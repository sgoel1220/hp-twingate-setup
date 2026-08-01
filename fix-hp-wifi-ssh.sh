#!/usr/bin/env bash
# HP only: disable wifi powersave + sshd keepalives. Prefer ethernet.
set -euo pipefail

echo "=== before ==="
hostname -I || true
ip -br a || true
iw dev wlo1 link 2>/dev/null || true

IFACE="${1:-wlo1}"

echo "=== disable Wi-Fi power save on $IFACE ==="
if command -v iw >/dev/null; then
  sudo iw dev "$IFACE" set power_save off || true
  iw dev "$IFACE" get power_save 2>/dev/null || true
fi
if command -v nmcli >/dev/null; then
  CONN=$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v d="$IFACE" '$2==d{print $1; exit}')
  if [ -n "${CONN:-}" ]; then
    echo "NM connection: $CONN"
    sudo nmcli connection modify "$CONN" 802-11-wireless.powersave 2 || true
    sudo nmcli connection up "$CONN" || true
  fi
fi

echo "=== sysctls ==="
sudo tee /etc/sysctl.d/99-ssh-lan.conf >/dev/null <<'EOF'
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
EOF
sudo sysctl --system >/dev/null 2>&1 || sudo sysctl -p /etc/sysctl.d/99-ssh-lan.conf || true

echo "=== sshd keepalives ==="
sudo tee /etc/ssh/sshd_config.d/99-keepalive.conf >/dev/null <<'EOF'
ClientAliveInterval 15
ClientAliveCountMax 12
TCPKeepAlive yes
EOF
sudo systemctl enable --now ssh 2>/dev/null || sudo systemctl enable --now sshd
sudo systemctl reload ssh 2>/dev/null || sudo systemctl reload sshd 2>/dev/null || sudo systemctl restart ssh

echo "=== after ==="
iw dev "$IFACE" link 2>/dev/null || true
iw dev "$IFACE" get power_save 2>/dev/null || true
ss -lntp | grep ':22' || true
echo
echo "Done. Strongly prefer ethernet over Wi-Fi for SSH."
echo "If IP is not 192.168.1.10, update Mac: ssh sg@NEW_IP"
