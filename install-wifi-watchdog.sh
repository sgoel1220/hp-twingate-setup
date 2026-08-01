#!/usr/bin/env bash
# HP only. Installs wifi-watchdog as a systemd service (SSID Goel / wlo1).
set -euo pipefail
cd "$(dirname "$0")"
sudo env WIFI_IFACE="${WIFI_IFACE:-wlo1}" WIFI_SSID="${WIFI_SSID:-Goel}" INTERVAL_SEC="${INTERVAL_SEC:-15}" \
  bash ./wifi-watchdog.sh install
echo
echo "Logs: journalctl -u wifi-watchdog -f"
echo "Also:  tail -f /var/log/wifi-watchdog.log"
