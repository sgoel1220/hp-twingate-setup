# Twingate: `lifeos-hp` (172.20.0.254) connectivity diagnosis

**Date:** 2026-08-01  
**Tenant:** `acmc.twingate.com`  
**User:** `ssearchitout@gmail.com` (admin)  
**Client:** macOS Twingate (`utun4`, client IP `100.96.0.2`)  
**Remote network:** Homelab Network (`301681`)

---

## Prompt (copy/paste for follow-up)

```text
Diagnose / fix Twingate access to resource lifeos-hp at 172.20.0.254.

Context already verified from the Mac client:
- Twingate is connected (utun4, 100.96.0.2).
- Resource lifeos-hp is configured as type=ip address=172.20.0.254 (no DNS aliases).
- Client policy ALLOW; route 172.20.0.254/32 goes via utun4.
- TCP connect to 22/80/443/3389/445/5900 appears to succeed instantly, but
  application data never arrives (SSH banner timeout, HTTP 0 bytes, RDP/SMB hang).
- Control: resource vostro (192.168.0.146) WORKS (SSH banner OpenSSH_9.6p1).
- Control: resource ee (192.168.1.10) FAILS the same way as lifeos-hp.
- Connector direct path times out (local peer ~172.21.0.2 / public 219.91.170.93);
  traffic uses relay_hydra and that path is Connected.
- Hostname "lifeos-hp" does NOT resolve (NXDOMAIN). Use IP or add a Twingate alias.

Root cause hypothesis (client-side ruled out):
Connector cannot complete sessions to 172.20.0.254 (host down, wrong IP,
firewall blocking connector, or host not on a network the connector can reach).

Tasks:
1. From the Twingate Connector host, verify reachability to 172.20.0.254
   (ping, nc -vz 172.20.0.254 3389/22/80).
2. On lifeos-hp: confirm power/IP, Windows firewall allows connector subnet,
   disable sleep if needed.
3. In acmc.twingate.com Admin: confirm resource address + Connector health
   for Homelab Network.
4. Optionally add DNS alias for lifeos-hp; do not rely on resource display name.
5. Retest from Mac: nc -v 172.20.0.254 22 (or 3389) must return real banner/data,
   not just "Connection succeeded".
```

---

## Findings summary

### Client-side: OK

| Check | Result |
|--------|--------|
| Twingate app + tunnel provider | Running |
| Tunnel interface | `utun4` up |
| Auth / admin | Logged in, 3 accessible resources |
| Resource definition | `lifeos-hp` → `172.20.0.254` |
| Route | `172.20.0.254/32` → `utun4` |
| Policy | `authorize_flow: ALLOW` |

### End-to-end data path: BROKEN for lifeos-hp

| Check | Result |
|--------|--------|
| DNS `lifeos-hp` | NXDOMAIN |
| Ping `172.20.0.254` | No reply (not diagnostic alone) |
| TCP connect (many ports) | Instant “success” (local proxy accept) |
| SSH banner | Timeout during banner exchange |
| HTTP | Connect then 0 bytes / timeout |
| RDP / SMB / HTTPS | No usable application data |

### Resource comparison (same network, same client)

| Resource | Address | App-layer |
|----------|---------|-----------|
| vostro | `192.168.0.146` | **Works** (SSH banner) |
| ee | `192.168.1.10` | Fails (hang after connect) |
| lifeos-hp | `172.20.0.254` | Fails (hang after connect) |

### Connector / transport notes

```text
direct_local  → TIMEOUT (peer ~172.21.0.2:50465; earlier 172.20.0.2)
direct_public → TIMEOUT (peer 219.91.170.93:21628)
relay_hydra   → Connected (e.g. 167.71.239.77:30002)
```

Relay works for **vostro**, so client→relay→connector path is viable.  
Failure is **connector → lifeos-hp (172.20.0.254)**.

### Resource SD (from client logs)

```text
lifeos-hp  id=3651340  type=ip  address=172.20.0.254  icmp=true  (no aliases)
vostro     id=3518229  type=ip  address=192.168.0.146 alias life.os
ee         id=3445343  type=ip  address=192.168.1.10
```

---

## Root cause

**Not** Mac config, Twingate login, or missing resource entry.

**Yes:** Twingate Connector cannot complete TCP sessions to `172.20.0.254`.  
Likely host offline/asleep, wrong IP, firewall blocking connector, or L2/L3 isolation.

Secondary: resource **name** `lifeos-hp` is not DNS — connect via IP or add an alias in Admin.

---

## Fix checklist

### On remote network / Connector host

- [ ] Confirm `lifeos-hp` is powered on and still has IP `172.20.0.254`
- [ ] From **Connector** host: `ping 172.20.0.254` and `nc -vz 172.20.0.254 3389` (or 22/80)
- [ ] Windows firewall: allow traffic from connector IP/subnet
- [ ] Disable sleep / ensure host stays reachable
- [ ] Admin UI: Connector healthy on **Homelab Network**
- [ ] Admin UI: resource address correct

### On Mac client (after remote fix)

```bash
# Must return real protocol data, not just connect success
nc -v 172.20.0.254 22
nc -v 172.20.0.254 3389
curl -v --max-time 8 http://172.20.0.254/
```

Optional:

- Use IP `172.20.0.254` until a DNS alias exists
- Add alias in Twingate Admin (e.g. `lifeos-hp` or `lifeos-hp.home`)
- Later: fix direct connector path (NAT/firewall to connector public/local peer) for lower latency

---

## Log references (client)

Path: `/var/log/twingate/com.twingate.macos.tunnelprovider.txt`

```text
authorize_flow: ALLOW ... ->172.20.0.254:22 ... transport=relay_hydra
network_transport: TIMEOUT transport=direct_local|direct_public
relay-hydra state: Connected
Got SD data ... with 3 accessible resources
```

---

## Do not waste time on

- Reinstalling Twingate on Mac (client path works for vostro)
- Fixing DNS for name `lifeos-hp` alone (IP path already fails at app layer)
- Using ping as sole success criteria
- Changing local `/etc/hosts` without fixing connector→host reachability
