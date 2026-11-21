---
name: vps-9router-model-combo
description: Discover, verify, and change model combos in the 9router Docker container on a remote VPS.
category: devops
---

# 9router Model Combo Verification

Class-level technique for discovering, verifying, and changing model combos in the 9router Docker container on a remote VPS.

## User Preferences
- Bahasa Indonesia unless explicitly switched to English. Keep answers short and targeted; no long explanations.
- When asked to "cek/model", default to Indonesia.

## Trigger
- User asks to change or verify model combos in docker 9router
- User asks to discover available models in 9router

## Steps

### 1. Verify container and paths
```bash
docker exec 9router ls -la /app/data/
docker exec 9router ls -la /app/data/db/
```
Key locations:
- Model catalog: `/app/data/model-catalog.json`
- Combo DB: `/app/data/db/data.sqlite` (no `sqlite3` binary — query via Node `better-sqlite3`)
- Health: `GET http://127.0.0.1:20128/api/health`

### 2. Known structure (from current session)
- 9router is a **cloud router**, not a local LLM server. Image `decolua/9router:latest`, port 20128.
- 6,446 models in catalog across 48 provider prefixes (`model-catalog.json`).
- Keys format `<provider>:<model-name>`, e.g. `openai:gpt-4o`, `deepseek:deepseek-flash`.
- Free/tier models carry a `-free` suffix (e.g. `oc:deepseek-v4.1-flash-free`, `opencode:deepseek-v4.1-flash-free`).
- Combo DB table `combos` has columns `id, name, kind, models, createdAt, updatedAt`.
- Current combo `9router-combo`:
  `oc/minimax-m3.1-flash-free | oc/big-pickle | oc:deepseek-v4.1-flash-free | oc:glm-5.3-flash-free`
- `providerNodes` and `proxyPools` tables are empty.

### 3. Dump combos from SQLite (no sqlite3 CLI)
```bash
cat > /tmp/dump-combos.cjs <<'EOF'
const SQL = require('sql.js');
const fs = require('fs');
const db = new SQL.Database(fs.readFileSync('/app/data/db/data.sqlite'));
const rows = db.exec('SELECT id, name, kind, models FROM combos').map(r => r.values);
console.log(JSON.stringify(rows, null, 2));
EOF
docker cp /tmp/dump-combos.cjs 9router:/tmp/dump-combos.cjs
docker exec 9router sh -c 'cd /app/data/runtime && NODE_PATH=/app/data/runtime/node_modules node /tmp/dump-combos.cjs'
```
The container lacks `sqlite3` CLI and `python3` sqlite module; `sql.js` (wasm) is the reliable path.

### 4. List available models
```bash
docker exec 9router cat /app/data/model-catalog.json | NODE_PATH=/app/node_modules node -e "
const fs = require('fs');
const d = JSON.parse(fs.readFileSync('/app/data/model-catalog.json','utf8'));
console.log(Object.keys(d.models).join('\n'));
"
```
Tip: filter for DeepSeek / free:
```bash
docker exec 9router node -e "
const fs = require('fs');
const d = JSON.parse(fs.readFileSync('/app/data/model-catalog.json','utf8'));
const names = Object.keys(d.models);
console.log('DEEPSEEK:');
names.filter(n=>n.startsWith('deepseek')).forEach(n=>console.log('  '+n));
console.log('FREE:');
names.filter(n=>n.endsWith('-free')).forEach(n=>console.log('  '+n));
"
```

### 5. Check current combo in SQLite
Same as step 3; look at `combos` table.

### 6. Verify combo validity
Every combo should have at least one model present in `model-catalog.json` under its provider; otherwise it fails health/sync.

### 7. Change combos (via SQLite, after backup)
```bash
# Backup first
docker exec 9router cp /app/data/db/data.sqlite /tmp/data.sqlite.backup

# Edit combos table via Node + sql.js (verified pattern):
#   INSERT OR REPLACE INTO combos(id, name, kind, models, createdAt, updatedAt) VALUES(?, ?, ?, ?, ?, ?)
# /app/data/db/data.sqlite is SQLite — use better-sqlite3 or sql.js
```

### 8. Check combo API (auth required)
```bash
# Unauthenticated 9router returns 401 for /api/*
curl -s http://127.0.0.1:20128/api/combos
```

## Pitfalls (First-Class)
- Do NOT hand-edit `model-catalog.json` — it is synced from external source; `etag`, `syncedAt`, and headers regenerate on next boot.
- `/api/*` returns 401 unless valid JWT (from UI login or API key).
- `TypeError: Failed to parse body as FormData` / `[modelCatalog] sync failed` / 400 "Model is unavailable" are transient — verify via `/api/health` before reacting.
- **No `sqlite3` CLI**: the container has `better-sqlite3` Node module and `sql.js` (wasm). Use Node + sql.js for dumps.
- Use `oc:<model>` style keys for local adapters; verify the adapter exists under `kv` (key `oc|<id>|llm`), NOT under `model-catalog.json`. This session's results showed `oc:*` models exist only in the `kv` table (SQLite), and model-catalog.json (6446 models, 48 provider prefixes) contains no `oc:*` entries. To verify a combo model, query `combos` table, then check each model in `kv`, and cross-check `usageHistory` for status `ok`.

## Session Notes (2026-11-20)
- 9router is a **cloud router**, not a local LLM server. Image `decolua/9router:latest`, port 20128.
- Combo `9router-combo` (id `74285da3-fe7e-447b-b873-862bcf8f7f47`) contains 4 models: `oc/minimax-m3.1-flash-free | oc/big-pickle | oc:deepseek-v4.1-flash-free | oc:glm-5.3-flash-free`.
- All 4 models are verifiable in the `kv` table and all are in active use (status `ok` in `usageHistory` 19-20 Nov 2026).
- `providerNodes` and `proxyPools` tables are empty.
- Provider connections: `openrouter` (active), `poolside` (active), `gemini` (unavailable/502 timeout).
- Usage is served through provider `opencode`, not a separate provider node.
- To check a combo model: (1) dump `combos` from SQLite, (2) verify each model exists as `oc|<id>|llm` in `kv`, (3) confirm recent usage in `usageHistory` with status `ok`.

## Related
- `devops/server-remote-management` — remote VPS access, bind mount write path
- `devops/vps-container-health` — container health checks
- `devops/inference-model-discovery` — Hermes agent model discovery
