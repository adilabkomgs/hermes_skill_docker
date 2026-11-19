# Hermes Config Inspection (Container)

## Overview
How to discover which model Hermes is actually using, and what custom providers are configured, by reading the live config inside the running container.

## Locations
- Config: `/root/.hermes/config.yaml` (inside the `hermes-agent-service` container)
- Env: `/root/.hermes/.env`
- State DB: `/root/.hermes/state.db` (SQLite)
- Skills: `/root/.hermes/skills/`

## Read the active model
```bash
docker exec hermes-agent-service sh -c 'cat /root/.hermes/config.yaml' | head -80
```

Key fields:
```yaml
model:
  default: meituan/longcat-2.5:free
  provider: nous
  base_url: https://inference-api.nousresearch.com/v1
custom_providers:
  - name: 9router-combo
    base_url: https://<vps-ip>/v1
    model: 9router-combo
    models:
      - 9router-combo
      - gemini/gemini-4-argon
      ...
```

## What this tells you
- `model.default` — the model actually answering right now
- `custom_providers` — all routers/providers configured (9router, local, etc.)
- `models:` list under a provider — the models exposed by that provider
- `session_reset.mode` — whether sessions auto-reset
- `platform_toolsets` — which toolsets are enabled per platform

## SQLite State (usage history)
The container has **no `sqlite3` binary**. Use the bundled `better-sqlite3` Node module:
```bash
docker exec hermes-agent-service sh -c 'cd /app && node -e "const db=require(\"better-sqlite3\")(\"/root/.hermes/state.db\"); console.log(db.prepare(\"SELECT name FROM sqlite_master WHERE type=\\\"table\\\"\").all());"'
```
(Adjust path if the DB is elsewhere; check `/root/.hermes/state.db` first.)

## Verified Config Snapshot (Nov 2026)
- Default model: `meituan/longcat-2.5:free` via `nous`
- Custom providers: `Local (127.0.0.1:20128)` and `9router-combo`
- 9router-combo exposes 20 models (gemini family, ps/laguna, oc/* free tiers, mmf/mimo-auto)

## Pitfalls
- `docker exec` uses `sh`, not `bash` — use `sh -c '...'` to avoid "executable file not found"
- Config is owned by uid 1001 (hermes) inside the container; `cat` works, edits may need matching uid
- Do NOT paste API keys from config.yaml into chat or logs — they are masked in tool output but still sensitive
- `state.db` has WAL files (`state.db-wal`, `state.db-shm`); copy all three if dumping
