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

### Mac client diagnosis (lifeos-hp unreachable)

When Twingate shows the resource but Mac cannot use SSH/RDP/HTTP, use **`LIFEOS_HP_DIAGNOSIS.md`**:

```text
Follow LIFEOS_HP_DIAGNOSIS.md. Client-side Twingate is OK; fix Connector → host path for 172.20.0.254 (or current HP IP). Confirm host up, correct IP in Admin, firewall allows connector. Retest with nc banner, not just TCP connect.
```

### Collect diagnostics from HP (for remote review)

On the **HP**:

```bash
git clone https://github.com/sgoel1220/hp-twingate-setup.git
cd hp-twingate-setup
# or: git pull
bash collect-hp-diag.sh
```

Writes **`HP_DIAG_REPORT.md`** and tries `git commit` + `git push`.  
If push fails (auth), run:

```bash
git add HP_DIAG_REPORT.md
git commit -m "Add HP_DIAG_REPORT"
git push
```

## Files

| File | Purpose |
|------|---------|
| `collect-hp-diag.sh` | **Run on HP** — writes `HP_DIAG_REPORT.md` and pushes |
| `HP_DIAG_REPORT.md` | Latest on-host diag output (generated; do not hand-edit) |
| `HP_CHANGE_IP.md` | Move HP to `172.20.0.2`, stop sharing `172.20.0.1` with Vostro |
| `HP_TWINGATE_SETUP.md` | Full context + Twingate Admin + Mac tests + troubleshooting |
| `LIFEOS_HP_DIAGNOSIS.md` | Mac client diagnosis: lifeos-hp TCP connects but app data hangs |
| `README.md` | This file |
