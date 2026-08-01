#!/usr/bin/env bash
# HP only. Writes HP_DIAG_REPORT.md then git commit+push if possible.
#   git pull && bash collect-hp-diag.sh

set -u

REPORT="HP_DIAG_REPORT.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

run() {
  local title="$1"
  shift
  echo
  echo "### ${title}"
  echo
  echo '```text'
  if "$@" 2>&1; then
    :
  else
    echo "(exit $?)"
  fi
  echo '```'
}

{
  echo "# HP_DIAG_REPORT"
  echo
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"
  echo "Local:     $(date +%Y-%m-%dT%H:%M:%S%z)"
  echo "Pwd:       $(pwd)"
  echo "User:      $(whoami) uid=$(id -u) gid=$(id -g)"
  echo
  echo "## Identity"
  run "hostname" hostname
  run "uname" uname -a
  run "whoami / id" id

  echo
  echo "## Addresses (all)"
  run "hostname -I" bash -c 'hostname -I 2>/dev/null || true'
  run "ip -br a" bash -c 'ip -br a 2>/dev/null || ip addr 2>/dev/null || ifconfig 2>/dev/null || true'
  run "ip -4 addr" bash -c 'ip -4 addr 2>/dev/null || true'

  echo
  echo "## Routes"
  run "ip route" bash -c 'ip route 2>/dev/null || route -n 2>/dev/null || true'
  run "default route" bash -c 'ip route show default 2>/dev/null || true'

  echo
  echo "## DNS"
  run "resolvectl" bash -c 'resolvectl status 2>/dev/null | head -60 || cat /etc/resolv.conf 2>/dev/null || true'

  echo
  echo "## SSH host keys (fingerprints)"
  run "ed25519 host key" bash -c '
    for f in /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_rsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub; do
      if [ -f "$f" ]; then
        echo "== $f =="
        ssh-keygen -lf "$f" 2>/dev/null || true
        cat "$f" 2>/dev/null || true
      fi
    done
  '

  echo
  echo "## sshd service"
  run "systemctl ssh/sshd" bash -c '
    systemctl is-active ssh 2>/dev/null; systemctl is-enabled ssh 2>/dev/null
    systemctl is-active sshd 2>/dev/null; systemctl is-enabled sshd 2>/dev/null
    systemctl status ssh --no-pager -l 2>/dev/null | head -40 || true
    systemctl status sshd --no-pager -l 2>/dev/null | head -40 || true
  '

  echo
  echo "## Listeners (22 / ssh)"
  run "ss -lntp" bash -c 'ss -lntp 2>/dev/null || netstat -lntp 2>/dev/null || true'
  run "grep :22" bash -c 'ss -lntp 2>/dev/null | grep -E ":22|:ssh" || netstat -lntp 2>/dev/null | grep -E ":22|:ssh" || echo "(no :22 listener found)"'

  echo
  echo "## sshd_config (relevant)"
  run "sshd -T (effective)" bash -c 'sudo -n sshd -T 2>/dev/null | grep -iE "^(port|listenaddress|permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers|denyusers)" || sshd -T 2>/dev/null | grep -iE "^(port|listenaddress|permitrootlogin|passwordauthentication|pubkeyauthentication)" || echo "(sshd -T failed — need sudo?)"'
  run "config files" bash -c '
    grep -rEn "^(Port|ListenAddress|PasswordAuthentication|PubkeyAuthentication|PermitRootLogin|AllowUsers)" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null || true
  '

  echo
  echo "## Firewall"
  run "ufw" bash -c 'sudo -n ufw status verbose 2>/dev/null || ufw status verbose 2>/dev/null || echo "(ufw n/a)"'
  run "iptables INPUT" bash -c 'sudo -n iptables -L INPUT -n -v 2>/dev/null | head -40 || echo "(iptables n/a)"'
  run "nft" bash -c 'sudo -n nft list ruleset 2>/dev/null | head -80 || echo "(nft n/a)"'

  echo
  echo "## Local TCP self-tests (must show success for SSH path)"
  run "nc/bash /dev/tcp checks" bash -c '
    targets="127.0.0.1 172.20.0.1 172.20.0.2 172.20.0.254 172.17.0.1"
    # also add every global IPv4 on this host
    extra=$(hostname -I 2>/dev/null || true)
    for ip in $targets $extra; do
      [ -z "$ip" ] && continue
      # de-dup later ok
      if command -v nc >/dev/null 2>&1; then
        if nc -z -w 2 "$ip" 22 >/dev/null 2>&1; then
          echo "$ip:22 OPEN (nc)"
        else
          echo "$ip:22 closed/fail (nc)"
        fi
      elif [ -e /dev/tcp ]; then
        if timeout 2 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
          echo "$ip:22 OPEN (/dev/tcp)"
        else
          echo "$ip:22 closed/fail (/dev/tcp)"
        fi
      else
        echo "$ip:22 (no nc and no /dev/tcp)"
      fi
    done | sort -u
  '

  echo
  echo "## SSH banner locally (first line)"
  run "banners" bash -c '
    for ip in 127.0.0.1 172.20.0.254 172.20.0.1 172.20.0.2; do
      echo -n "$ip: "
      if command -v nc >/dev/null 2>&1; then
        timeout 3 nc -w 2 "$ip" 22 2>/dev/null | head -1 || echo "(no banner)"
      else
        timeout 3 bash -c "exec 3<>/dev/tcp/$ip/22 && head -1 <&3" 2>/dev/null || echo "(no banner)"
      fi
    done
  '

  echo
  echo "## Users / sg"
  run "id sg" bash -c 'id sg 2>/dev/null || echo "user sg missing"'
  run "sg authorized_keys" bash -c '
    for h in /home/sg /home/*; do
      [ -d "$h" ] || continue
      ak="$h/.ssh/authorized_keys"
      if [ -f "$ak" ]; then
        echo "== $ak =="
        wc -l "$ak"
        # fingerprints only, not full keys if many
        ssh-keygen -lf "$ak" 2>/dev/null | head -20 || head -5 "$ak"
      fi
    done
  '

  echo
  echo "## Docker / odd interfaces"
  run "docker" bash -c 'command -v docker >/dev/null && docker ps --format "table {{.Names}}\t{{.Ports}}" 2>/dev/null | head -20 || echo "(no docker)"'
  run "172.17 bridge" bash -c 'ip -br a 2>/dev/null | grep -E "172\.17|docker|br-" || true'

  echo
  echo "## Connectivity toward gateway / connector hints"
  run "ping gateway" bash -c '
    gw=$(ip route show default 2>/dev/null | awk "/default/ {print \$3; exit}")
    echo "gateway=$gw"
    if [ -n "$gw" ]; then ping -c 2 -W 2 "$gw" 2>&1 || true; fi
  '
  run "ping 172.20.0.2 (connector historically)" bash -c 'ping -c 2 -W 2 172.20.0.2 2>&1 || true'
  run "ping 172.21.0.2 (connector peer seen from Mac)" bash -c 'ping -c 2 -W 2 172.21.0.2 2>&1 || true'

  echo
  echo "## Netplan / NM snippets"
  run "netplan files" bash -c 'ls -la /etc/netplan 2>/dev/null; for f in /etc/netplan/*.yaml /etc/netplan/*.yml; do [ -f "$f" ] || continue; echo "---- $f ----"; cat "$f"; done 2>/dev/null || true'
  run "nmcli" bash -c 'nmcli -t -f NAME,UUID,TYPE,DEVICE,STATE connection show 2>/dev/null | head -30 || echo "(nmcli n/a)"'

  echo
  echo "## Summary block (machine-parsed)"
  echo
  echo '```text'
  echo "hostname=$(hostname 2>/dev/null)"
  echo "user=$(whoami)"
  echo "ips=$(hostname -I 2>/dev/null | tr -s " " ",")"
  echo "sshd_active=$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo unknown)"
  echo "listen22=$(ss -lntp 2>/dev/null | grep -E ':22\s' | head -3 | tr '\n' '|' || echo none)"
  fp=$(ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null | awk "{print \$2}" || true)
  echo "ed25519_fingerprint=${fp:-unknown}"
  echo "has_172_20_0_1=$(ip -4 addr 2>/dev/null | grep -c '172.20.0.1' || echo 0)"
  echo "has_172_20_0_254=$(ip -4 addr 2>/dev/null | grep -c '172.20.0.254' || echo 0)"
  echo "has_172_20_0_2=$(ip -4 addr 2>/dev/null | grep -c '172.20.0.2' || echo 0)"
  echo "has_172_17_0_1=$(ip -4 addr 2>/dev/null | grep -c '172.17.0.1' || echo 0)"
  echo '```'
  echo
  echo "=== END HP_DIAG_REPORT ==="
} >"$REPORT"

echo "Wrote: $SCRIPT_DIR/$REPORT"
wc -l "$REPORT"

if [ -d .git ]; then
  echo
  echo "Git remote:"
  git remote -v 2>/dev/null || true
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add "$REPORT" || true
    if git diff --staged --quiet 2>/dev/null; then
      echo "No report changes to commit (identical to last?)."
    else
      if git commit -m "Add HP_DIAG_REPORT from $(hostname) at $(date -u +%Y-%m-%dT%H:%MZ)"; then
        echo "Committed $REPORT"
        if git push origin HEAD 2>&1; then
          echo "Pushed OK."
        else
          echo "Push failed. Run manually:"
          echo "  git push -u origin HEAD"
        fi
      else
        echo "Commit failed — push manually after fixing git user/email."
      fi
    fi
  fi
else
  echo
  echo "Not a git checkout. Copy report or clone repo and re-run:"
  echo "  git clone https://github.com/sgoel1220/hp-twingate-setup.git"
  echo "  cd hp-twingate-setup && bash collect-hp-diag.sh"
fi

echo
echo "Done. Mac operator will read: HP_DIAG_REPORT.md on GitHub main."
