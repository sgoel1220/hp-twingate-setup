#!/usr/bin/env bash
# Run on HP as sg. Adds this Mac's SSH public key for passwordless login.
set -euo pipefail
PUB='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPyy8NWPYPu/yamwReuh+6CutG2Sca8JN7iOMfrGuYjM mac-docker-builder'
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
if grep -qF 'mac-docker-builder' "$HOME/.ssh/authorized_keys" 2>/dev/null || grep -qF 'AAAAC3NzaC1lZDI1NTE5AAAAIPyy8NWPYPu/yamwReuh+6CutG2Sca8JN7iOMfrGuYjM' "$HOME/.ssh/authorized_keys" 2>/dev/null; then
  echo "Key already present in authorized_keys"
else
  echo "$PUB" >> "$HOME/.ssh/authorized_keys"
  echo "Key added."
fi
ssh-keygen -lf "$HOME/.ssh/authorized_keys" || true
echo "From Mac test: ssh sg@192.168.1.10"
