#!/usr/bin/env bash
# HP only. Poll Wi-Fi; reconnect if link/gateway/IP dies.
# Env: WIFI_IFACE WIFI_SSID WIFI_CONN GATEWAY INTERVAL_SEC FAIL_THRESHOLD LOG_FILE

set -u

IFACE="${WIFI_IFACE:-wlo1}"
SSID="${WIFI_SSID:-Goel}"
CONN="${WIFI_CONN:-}"
GATEWAY="${GATEWAY:-}"
INTERVAL="${INTERVAL_SEC:-15}"
FAIL_NEED="${FAIL_THRESHOLD:-2}"
LOG_FILE="${LOG_FILE:-/var/log/wifi-watchdog.log}"
STATE_DIR="${STATE_DIR:-/run/wifi-watchdog}"
FAILS=0

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() {
  local line="[$(ts)] $*"
  echo "$line"
  if mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null && touch "$LOG_FILE" 2>/dev/null; then
    echo "$line" >>"$LOG_FILE"
  elif [ -w "${HOME:-/tmp}" ]; then
    echo "$line" >>"${HOME}/wifi-watchdog.log"
  fi
}

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "ERROR: run as root (sudo). exiting"
    exit 1
  fi
}

detect_conn() {
  if [ -n "$CONN" ]; then
    echo "$CONN"
    return
  fi
  local c
  c=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | awk -F: -v d="$IFACE" '$2==d{print $1; exit}')
  if [ -n "$c" ]; then
    echo "$c"
    return
  fi
  c=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1; exit}')
  if [ -n "$c" ]; then
    echo "$c"
    return
  fi
  echo "$SSID"
}

detect_gateway() {
  if [ -n "$GATEWAY" ]; then
    echo "$GATEWAY"
    return
  fi
  ip route show default dev "$IFACE" 2>/dev/null | awk '/default/ {print $3; exit}'
}

iface_up() {
  [ -d "/sys/class/net/$IFACE" ] || return 1
  local st
  st=$(cat "/sys/class/net/$IFACE/operstate" 2>/dev/null || echo down)
  [ "$st" = "up" ] || [ "$st" = "unknown" ]
}

has_ipv4() {
  ip -4 -o addr show dev "$IFACE" 2>/dev/null | grep -q 'inet '
}

wifi_associated() {
  if command -v iw >/dev/null 2>&1; then
    iw dev "$IFACE" link 2>/dev/null | grep -q 'Connected to'
    return $?
  fi
  nmcli -t -f GENERAL.STATE device show "$IFACE" 2>/dev/null | grep -qi 'connected'
}

gateway_ok() {
  local gw
  gw=$(detect_gateway)
  [ -n "$gw" ] || return 1
  ping -c 1 -W 2 "$gw" >/dev/null 2>&1
}

powersave_off() {
  command -v iw >/dev/null 2>&1 || return 0
  iw dev "$IFACE" set power_save off 2>/dev/null || true
}

rfkill_unblock() {
  command -v rfkill >/dev/null 2>&1 || return 0
  rfkill unblock wifi 2>/dev/null || true
  rfkill unblock wlan 2>/dev/null || true
}

radio_on() {
  nmcli radio wifi on 2>/dev/null || true
}

reconnect() {
  local conn reason="$1"
  conn=$(detect_conn)
  log "RECONNECT reason=$reason iface=$IFACE conn=$conn ssid=$SSID"

  rfkill_unblock
  radio_on
  powersave_off

  ip link set "$IFACE" up 2>/dev/null || true

  nmcli device disconnect "$IFACE" 2>/dev/null || true
  sleep 1

  if nmcli connection up "$conn" ifname "$IFACE" 2>/dev/null; then
    log "RECONNECT ok via connection up name=$conn"
  elif nmcli device wifi connect "$SSID" ifname "$IFACE" 2>/dev/null; then
    log "RECONNECT ok via wifi connect ssid=$SSID"
  else
    log "RECONNECT failed; bouncing NetworkManager device"
    nmcli device set "$IFACE" managed yes 2>/dev/null || true
    nmcli networking off 2>/dev/null || true
    sleep 2
    nmcli networking on 2>/dev/null || true
    sleep 3
    nmcli connection up "$conn" ifname "$IFACE" 2>/dev/null \
      || nmcli device wifi connect "$SSID" ifname "$IFACE" 2>/dev/null \
      || log "RECONNECT still failed"
  fi

  powersave_off
  sleep 2
  log "state after: $(nmcli -t -f DEVICE,STATE,CONNECTION device status 2>/dev/null | tr '\n' ' ')"
  log "addrs: $(hostname -I 2>/dev/null || true)"
}

health_ok() {
  iface_up || { echo "iface_down"; return 1; }
  wifi_associated || { echo "not_associated"; return 1; }
  has_ipv4 || { echo "no_ipv4"; return 1; }
  gateway_ok || { echo "gateway_unreachable"; return 1; }
  echo "ok"
  return 0
}

install_systemd() {
  need_root
  local unit=/etc/systemd/system/wifi-watchdog.service
  local script_src
  script_src="$(cd "$(dirname "$0")" && pwd)/wifi-watchdog.sh"
  install -m 755 "$script_src" /usr/local/sbin/wifi-watchdog.sh

  cat >"$unit" <<EOF
[Unit]
Description=Wi-Fi reconnect watchdog
After=NetworkManager.service
Wants=NetworkManager.service

[Service]
Type=simple
ExecStart=/usr/local/sbin/wifi-watchdog.sh run
Restart=always
RestartSec=5
Environment=WIFI_IFACE=${IFACE}
Environment=WIFI_SSID=${SSID}
Environment=INTERVAL_SEC=${INTERVAL}
Environment=FAIL_THRESHOLD=${FAIL_NEED}
Environment=LOG_FILE=/var/log/wifi-watchdog.log

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now wifi-watchdog.service
  systemctl status wifi-watchdog.service --no-pager -l | head -25
  log "installed systemd unit wifi-watchdog.service"
}

run_loop() {
  need_root
  mkdir -p "$STATE_DIR"
  powersave_off
  radio_on
  log "START iface=$IFACE ssid=$SSID interval=${INTERVAL}s fail_threshold=$FAIL_NEED"

  while true; do
    local why
    if why=$(health_ok); then
      if [ "$FAILS" -ne 0 ]; then
        log "HEALTH recovered after fails=$FAILS"
      fi
      FAILS=0
      powersave_off
    else
      FAILS=$((FAILS + 1))
      log "HEALTH fail=$FAILS/$FAIL_NEED reason=$why"
      if [ "$FAILS" -ge "$FAIL_NEED" ]; then
        reconnect "$why"
        FAILS=0
      fi
    fi
    sleep "$INTERVAL"
  done
}

cmd="${1:-run}"
case "$cmd" in
  run) run_loop ;;
  install) install_systemd ;;
  once)
    need_root
    why=$(health_ok) && log "healthy" || reconnect "$why"
    ;;
  status)
    echo "iface=$IFACE"
    nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true
    iw dev "$IFACE" link 2>/dev/null || true
    ip -br a show "$IFACE" 2>/dev/null || true
    ip route show default 2>/dev/null || true
    ;;
  *)
    echo "usage: $0 run|install|once|status"
    exit 2
    ;;
esac
