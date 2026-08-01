# HP Agent Instructions — Change IP (fix Twingate clash)

**Run this on the HP host only.**  
**Do not run on Vostro / life.os.**

---

## Why you are doing this

`172.20.0.1` has been answered by **two different machines** at different times:

| Fingerprint | Host | Role |
|-------------|------|------|
| `SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U` | **HP (you)** | Target |
| `SHA256:fquW6eTqsli0eQkIR2ObJJ9NIeIUnHTpaedRiS0uPCc` | **Vostro** (`vostro`, also `192.168.0.146`) | Other box |

That caused SSH errors: `REMOTE HOST IDENTIFICATION HAS CHANGED`.  
Twingate is fine; **IP identity is not unique**. HP must move off any shared address.

Mac home LAN is `192.168.1.0/24` — do **not** put the Twingate-facing HP address on `192.168.1.x`.

---

## Goal

1. Confirm this machine is the **HP** (not Vostro).
2. Set a **permanent** address: **`172.20.0.2/24`** (if free).
3. **Never** use `172.20.0.1` or `192.168.0.146`.
4. Keep default gateway + DNS working so the Twingate Connector can reach you.
5. Keep **sshd :22** and user **`sg`** working.
6. Print a short report for Twingate Admin + Mac test commands.

---

## STOP conditions

Abort and report if:

- Hostname is `vostro`, or fingerprint is `SHA256:fquW6e…` → wrong machine.
- You cannot discover gateway/DNS and applying a static IP would likely brick remote access with no console.
- `172.20.0.2` is already taken by another host (pick next free `172.20.0.x` ≥ `.2`, still not `.1`).

---

## Steps

### 1) Identity check

```bash
hostname
whoami
hostname -I 2>/dev/null || ip -br a
ip route 2>/dev/null || route -n
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null || \
  ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Expected HP fingerprint (if key unchanged):

`SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U`

If fingerprint differs (rebuilt OS), continue but print the **new** fingerprint as source of truth.

### 2) Discover current network (do not guess gateway)

```bash
ip -br a 2>/dev/null || ifconfig
ip route show default 2>/dev/null
# note: INTERFACE, current IP(s), DEFAULT_GATEWAY, subnet
cat /etc/netplan/*.yaml 2>/dev/null
ls /etc/NetworkManager/system-connections 2>/dev/null
resolvectl status 2>/dev/null | head -40
```

Check if `.2` is free (from HP):

```bash
ping -c 1 -W 1 172.20.0.2 2>/dev/null && echo "BUSY?" || echo "likely free"
# arping if available: sudo arping -c 2 -I INTERFACE 172.20.0.2
```

### 3) Remove conflicting addresses

If this HP currently has **`172.20.0.1`** (or any address that Vostro also uses):

- Remove it from permanent config (netplan / NM / interfaces).
- Do not leave two static IPs that include `.1` “just in case.”

### 4) Apply permanent IP `172.20.0.2/24`

Use the stack already on the machine.

#### Netplan example (edit INTERFACE + GATEWAY)

```bash
# Replace INTERFACE_NAME and GATEWAY_IP with values from step 2
sudo tee /etc/netplan/99-hp-stable-ip.yaml >/dev/null <<'EOF'
network:
  version: 2
  ethernets:
    INTERFACE_NAME:
      dhcp4: false
      addresses:
        - 172.20.0.2/24
      routes:
        - to: default
          via: GATEWAY_IP
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
EOF
sudo chmod 600 /etc/netplan/99-hp-stable-ip.yaml
sudo netplan generate && sudo netplan apply
```

If another netplan file also configures the same NIC, **disable/merge** so you do not have conflicting DHCP+static.

#### NetworkManager sketch

```bash
nmcli -t -f NAME,DEVICE,STATE connection show --active
# nmcli connection modify <NAME> ipv4.method manual \
#   ipv4.addresses 172.20.0.2/24 ipv4.gateway <GW> ipv4.dns "1.1.1.1 8.8.8.8"
# nmcli connection up <NAME>
```

### 5) Verify local network + SSH

```bash
ip -br a
ip route
ping -c 2 GATEWAY_IP
sudo systemctl enable --now ssh 2>/dev/null || sudo systemctl enable --now sshd
sudo ss -lntp | grep -E ':22' || true
id sg
nc -zv 127.0.0.1 22
hostname -I
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

### 6) Firewall (only if blocking)

```bash
sudo ufw status 2>/dev/null
# if active and 22 denied: sudo ufw allow 22/tcp && sudo ufw reload
```

### 7) Do NOT touch Twingate Admin from the HP unless you have credentials

Human/operator must update Twingate after your report:

| Field | Value |
|-------|--------|
| Resource name | `hp` |
| Address | `172.20.0.2` (or the IP you actually set) |
| Ports | `22` |
| Remote Network | Same as existing Connector (the one that serves Vostro) |

Vostro keeps `172.20.0.1` and/or `192.168.0.146` — **exclusive**.

---

## Safety

- Prefer **console / physical access** if this is the only remote path; changing IP can drop your session.
- If you are connected over the old IP, apply config in a way that keeps a window to fix (tmux + `netplan try` if available):

```bash
sudo netplan try --timeout 120
# confirm connectivity; accept within timeout or it rolls back
```

- Do not wipe `/home/sg/.ssh` or disable PasswordAuthentication unless a working key is confirmed.
- Do not renumber Vostro in this task.
- Do not use `192.168.1.0/24` for the Twingate-facing address.

---

## Final report (print exactly)

```text
=== HP CHANGE IP REPORT ===
hostname: ...
confirmed_not_vostro: yes/no
old_ips: ...
new_ip: 172.20.0.2
prefix: /24
interface: ...
gateway: ...
dns: ...
sshd_port: 22
ssh_user: sg
ed25519_fingerprint: SHA256:...
ping_gateway: ok/fail
config_files_changed: ...
twingate_admin_resource_address: 172.20.0.2
twingate_admin_ports: 22
mac_test_commands: |
  route -n get 172.20.0.2
  ssh-keygen -R 172.20.0.2
  ssh sg@172.20.0.2
accept_fingerprint: SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U  # or NEW if rebuilt
reject_if_vostro: SHA256:fquW6eTqsli0eQkIR2ObJJ9NIeIUnHTpaedRiS0uPCc
=== END REPORT ===
```

---

## One-line agent prompt

```text
Follow HP_CHANGE_IP.md exactly. You are on the HP only. Move this host to permanent 172.20.0.2/24 (never 172.20.0.1 or 192.168.0.146). Keep gateway/DNS, sshd:22, user sg. Print the HP CHANGE IP REPORT block.
```

---

## After this succeeds (Mac operator)

```bash
# Twingate Admin: Resource hp → 172.20.0.2 port 22, then:
route -n get 172.20.0.2    # must be utun (Twingate), not en0
ssh-keygen -R 172.20.0.2
ssh sg@172.20.0.2
# fingerprint must be HP (0sgqaJ…), never Vostro (fquW6e…)
```

Optional `~/.ssh/config`:

```sshconfig
Host hp
    HostName 172.20.0.2
    User sg
    ServerAliveInterval 30
    ServerAliveCountMax 20

Host vostro
    HostName 172.20.0.1
    User sg
    ServerAliveInterval 30
    ServerAliveCountMax 20
```
