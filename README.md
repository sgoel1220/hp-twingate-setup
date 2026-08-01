# hp-twingate-setup

Runbook for making the **HP** machine reachable over **Twingate SSH** (separate from Vostro/life.os).

## On the HP

```bash
git clone https://github.com/sgoel1220/hp-twingate-setup.git
cd hp-twingate-setup
# Point your agent at:
#   HP_TWINGATE_SETUP.md
```

Or one-shot agent prompt (also at the bottom of the runbook):

```text
Follow HP_TWINGATE_SETUP.md end-to-end. Make this HP host SSH-reachable via Twingate as its own resource (prefer 172.20.0.2; never 172.20.0.1 / 192.168.0.146). Ensure sshd:22 + user sg. Print the final report block.
```

## Files

| File | Purpose |
|------|---------|
| `HP_TWINGATE_SETUP.md` | Full context + steps + Admin fields + Mac tests |
| `README.md` | This file |
