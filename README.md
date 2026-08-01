# hp-twingate-setup

Runbook for making the **HP** machine reachable over **Twingate SSH** (separate from Vostro/life.os).

## On the HP

```bash
git clone https://github.com/sgoel1220/hp-twingate-setup.git
cd hp-twingate-setup
# or: git pull
```

### Fix IP clash (current priority)

Point the HP agent at **`HP_CHANGE_IP.md`**:

```text
Follow HP_CHANGE_IP.md exactly. You are on the HP only. Move this host to permanent 172.20.0.2/24 (never 172.20.0.1 or 192.168.0.146). Keep gateway/DNS, sshd:22, user sg. Print the HP CHANGE IP REPORT block.
```

### Full Twingate setup (broader runbook)

```text
Follow HP_TWINGATE_SETUP.md end-to-end. Make this HP host SSH-reachable via Twingate as its own resource (prefer 172.20.0.2; never 172.20.0.1 / 192.168.0.146). Ensure sshd:22 + user sg. Print the final report block.
```

## Files

| File | Purpose |
|------|---------|
| `HP_CHANGE_IP.md` | **Do this now** — move HP to `172.20.0.2`, stop sharing `172.20.0.1` with Vostro |
| `HP_TWINGATE_SETUP.md` | Full context + Twingate Admin + Mac tests + troubleshooting |
| `README.md` | This file |
