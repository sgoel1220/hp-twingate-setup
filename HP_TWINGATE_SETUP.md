# HP Host — Twingate SSH Setup (Agent Runbook)

Run this on the **HP** machine (console, local LAN, or any shell already on the HP).  
Goal: make **this** host reachable from a Mac over **Twingate only** as its own resource — not via the Vostro / life.os box.

---

## Context (do not skip)

### Two different machines (do not mix them up)

| Role | Hostname / identity | Known LAN IPs | SSH ED25519 fingerprint | Twingate today |
|------|---------------------|---------------|-------------------------|----------------|
| **HP (THIS host — target)** | HP box you want | Historically `192.168.0.180`, `.181`, `.182` | `SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U` | **Not stably exposed** |
| **Vostro (NOT this host)** | `vostro` / life.os | `192.168.0.146`, also answers as `172.20.0.1` | `SHA256:fquW6eTqsli0eQkIR2ObJJ9NIeIUnHTpaedRiS0uPCc` | Already works via Twingate |

### Mac client (operator laptop)

- Home LAN: `192.168.1.8/24` (gateway `192.168.1.1`) — **do not require changing this**
- Twingate: connected (`utun4`, client CGNAT-ish `100.96.0.2`)
- Twingate resources currently installed on Mac routes:
  - `172.20.0.1/32` → **Vostro** (wrong if you wanted HP)
  - `192.168.0.146/32` → **Vostro**
  - `192.168.1.10/32` → route exists but **SSH times out** (broken / overlap / wrong host)
- SSH user expected: `sg`
- Mac SSH config currently only has:

```sshconfig
Host 192.168.1.10
    User sg
    ServerAliveInterval 30
    ServerAliveCountMax 20
```

### Why things broke

1. **`192.168.1.10` overlaps home LAN** `192.168.1.0/24` → unreliable via Twingate from home.
2. **`172.20.0.1` points at Vostro**, not HP. SSH to it lands on `sg@vostro` with IP `192.168.0.146`.
3. Host key warnings happened because **different machines answered the same Twingate IP at different times**.
4. **Ping is not a reliable Twingate test.** Prefer TCP/SSH. (ICMP sometimes works, often does not.)
5. On Mac, `ip` may be missing (`zsh: command not found: ip`) — use `ifconfig` / `ipconfig` there. On Ubuntu HP use `ip -br a` or `hostname -I`.

### Non-goals

- Do **not** renumber the Mac home LAN.
- Do **not** change Vostro networking unless required for Connector reachability.
- Do **not** share `172.20.0.1` or `192.168.0.146` with the HP.
- Do **not** delete Twingate entirely — only add/fix the HP resource mapping.

---

## Agent objective (success criteria)

When finished, all of the following must be true:

1. HP has a **stable, permanent IP** that does **not** sit on `192.168.1.0/24`.
2. Preferred address: **`172.20.0.2/24`** (if free on the remote network). Alternatives: other free `172.20.0.x`, or `10.x` / `172.16.x` on the same L2/L3 as the Twingate Connector.
3. `sshd` listens on port **22** (or document the real port) on that IP.
4. User **`sg`** can authenticate (existing keys/password policy — do not lock yourself out).
5. Twingate **Connector** (on the remote network) can reach `HP_IP:22`.
6. You printed **exact Twingate Admin fields** and a **Mac test command**.
7. SSH host key fingerprint on HP is reported; ideally matches  
   `SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U`  
   (If the box was rebuilt and the key differs, print the **new** fingerprint clearly and treat that as the source of truth going forward.)

---

## Step-by-step (execute on HP)

### 0) Confirm you are on the HP

```bash
hostname
hostname -I 2>/dev/null || ip -br a
whoami
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null || ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

- If fingerprint is `SHA256:fquW6eTqsli0eQkIR2ObJJ9NIeIUnHTpaedRiS0uPCc` or hostname is `vostro` → **STOP**. You are on Vostro, not HP.
- Expected HP fingerprint (historical): `SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U`

### 1) Inventory network

```bash
ip -br a 2>/dev/null || ifconfig
ip route 2>/dev/null || route -n
cat /etc/netplan/*.yaml 2>/dev/null
ls /etc/NetworkManager/system-connections 2>/dev/null
resolvectl status 2>/dev/null | head -40
```

Identify:

- Interface connected to the lab/remote LAN (same side as Twingate Connector)
- Current DHCP vs static
- Free IP to use (prefer `172.20.0.2`)

### 2) Assign stable IP (prefer 172.20.0.2)

Pick one approach that matches how this host is configured.

**If netplan:**

```bash
# Example only — adjust NIC name, gateway, DNS to match THIS network.
# Do not copy gateway blindly. Discover gateway with: ip route | grep default
sudo tee /etc/netplan/99-hp-twingate.yaml >/dev/null <<'EOF'
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
sudo netplan generate && sudo netplan apply
```

**If NetworkManager:**

```bash
# nmcli connection show
# Then modify the active connection with ipv4.addresses 172.20.0.2/24, gateway, dns, ipv4.method manual
```

**Rules:**

- Never take `172.20.0.1` or `192.168.0.146` (Vostro).
- Avoid `192.168.1.0/24` for the Twingate-facing address (home overlap).
- Keep Connector ↔ HP L3 path working (same subnet or routed).

Verify:

```bash
hostname -I
ip -br a
ping -c 2 GATEWAY_OR_CONNECTOR
```

### 3) Ensure SSH server

```bash
sudo systemctl enable --now ssh 2>/dev/null || sudo systemctl enable --now sshd
sudo ss -lntp | grep -E ':22|:ssh' || sudo netstat -lntp | grep ssh
sudo grep -E '^(Port|ListenAddress|PasswordAuthentication|PubkeyAuthentication)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null
```

- Listening on `0.0.0.0:22` or the chosen IP is fine.
- Confirm user `sg` exists and can log in:

```bash
id sg
sudo -u sg -i true
ls -la /home/sg/.ssh 2>/dev/null
```

If adding an authorized key for the Mac, append the Mac public key to `/home/sg/.ssh/authorized_keys` (do not remove existing keys unless asked).

### 4) Local self-test on HP

```bash
HP_IP=$(hostname -I | awk '{print $1}')  # or set explicitly to 172.20.0.2
echo "HP_IP=$HP_IP"
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
nc -zv 127.0.0.1 22
# optional: ssh sg@127.0.0.1 / ssh sg@$HP_IP from another local session
```

### 5) Connector path check (best effort)

If you know the Connector host IP/name:

```bash
ping -c 2 CONNECTOR_IP
nc -zv CONNECTOR_IP 22   # only if connector runs ssh; mainly need Connector -> HP:22
```

If you can run commands **on the Connector**:

```bash
ping -c 2 172.20.0.2
nc -zv 172.20.0.2 22
```

Twingate clients can only reach what the **Connector** can reach.

### 6) Firewall (if enabled)

```bash
sudo ufw status 2>/dev/null
# if ufw active:
# sudo ufw allow 22/tcp
# sudo ufw reload
sudo iptables -L INPUT -n 2>/dev/null | head -30
```

---

## Twingate Admin (human or agent with admin access)

Create or update **one** Resource for the HP only:

| Field | Value |
|-------|--------|
| Name | `hp` |
| Address | `172.20.0.2` (or the stable IP you actually set) |
| Ports | `22` (add more only if needed) |
| Alias / DNS (optional) | e.g. `hp.internal` if you use Twingate DNS |
| Remote Network | **Same** network as the existing Connector that already serves Vostro |
| Connector | Online Connector on that remote network |
| Access group | Same group as the Mac user who reaches Vostro today |

**Do not** point `172.20.0.1` at both Vostro and HP.  
**Optional cleanup:** fix or remove broken resource `192.168.1.10` if it was a failed HP attempt.

After save, on the Mac Twingate client the new IP should appear as a host route on `utun*`:

```bash
route -n get 172.20.0.2
# interface must be utun4 (or current Twingate utun), NOT en0
```

---

## Mac operator test (after Resource is live)

```bash
# clear any stale key for the new address
ssh-keygen -R 172.20.0.2 2>/dev/null

# must go via Twingate
route -n get 172.20.0.2

# SSH — accept ONLY the HP fingerprint
ssh sg@172.20.0.2
```

**Accept fingerprint:**

- HP: `SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U` (or the new one printed by this agent if rebuilt)
- **Reject** if you see Vostro: `SHA256:fquW6eTqsli0eQkIR2ObJJ9NIeIUnHTpaedRiS0uPCc`

Inside the session:

```bash
hostname          # must NOT be vostro
hostname -I       # should include 172.20.0.2 (or chosen IP)
```

### Recommended Mac `~/.ssh/config`

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

Usage:

```bash
ssh hp       # Twingate → HP
ssh vostro   # Twingate → Vostro
```

---

## Agent final report format (print exactly)

```text
=== HP TWINGATE SETUP REPORT ===
hostname: ...
os: ...
hp_ip: ...
ssh_port: 22
ssh_user: sg
ed25519_fingerprint: SHA256:...
sshd_active: yes/no
connector_can_reach_note: ...
twingate_admin:
  name: hp
  address: ...
  ports: 22
  remote_network: <same as existing Connector>
mac_test:
  route -n get <hp_ip>
  ssh sg@<hp_ip>
accept_fingerprint: SHA256:...
reject_if_vostro_fingerprint: SHA256:fquW6eTqsli0eQkIR2ObJJ9NIeIUnHTpaedRiS0uPCc
=== END REPORT ===
```

---

## Short prompt (if the agent only accepts a tiny instruction)

```text
Make this HP host SSH-reachable via Twingate as its own resource: set a stable IP (prefer 172.20.0.2, never 172.20.0.1/192.168.0.146 — those are Vostro), ensure sshd:22 and user sg work, print IP + ssh-keygen -lf ED25519 fingerprint (expect SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U).
Output exact Twingate Admin fields (address/ports/network) and Mac test: ssh sg@<IP>. Follow HP_TWINGATE_SETUP.md in this repo end-to-end and print the final report block.
```

---

## Troubleshooting cheat sheet

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Mac SSH to `172.20.0.1` shows `sg@vostro` | Resource is Vostro | Use dedicated HP IP resource |
| Host key suddenly changes | Two machines sharing one Twingate IP | One IP per host; unique Resources |
| `192.168.1.10` route on utun but SSH timeout | Overlap with home `192.168.1.0/24` or host down | Move HP to `172.20.0.2` |
| Ping fails but SSH works | Normal for some Twingate paths | Test with `ssh` / `nc -zv IP 22` |
| No utun route for new IP on Mac | Resource not saved / no access / client not refreshed | Check Admin access group; toggle Twingate off/on |
| Connector cannot `nc HP 22` | Wrong IP, firewall, sshd down, different VLAN | Fix LAN path first — Twingate cannot magic it |

---

## Safety

- Do not wipe `/home/sg/.ssh` or disable SSH until an alternate console exists.
- Do not apply netplan with a wrong gateway (you can brick remote access). Discover gateway first.
- Prefer additive config (`99-*.yaml`) over destroying the only working NIC config.
- If unsure whether you are on HP vs Vostro, **stop** and re-check fingerprint/hostname.
