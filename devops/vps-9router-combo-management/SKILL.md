---
name: vps-9router-combo-management
description: Manage 9router combo (model fallback/load-balancing) on VPS dcloud, backup/restore, and per-combo model changes.
---

# VPS 9router Combo Management

## When to use
- User asks: "change model combo in 9router", "add model to combos", "backup 9router data", "fix combos", "switch 9router model fallback".

## Core facts (verified 2026-11-20)
- 9router container: `decolua/9router:latest`, image tag from compose: `9router-docker/9router:latest`? — see deploy. Check the exact tag from docker-compose.yml.
- App data stored at `/app/data`, volume mapped to host.
- SQLite DB: `/app/data/db/data.sqlite`, table `combos` has columns: `id, name, kind, models, createdAt, updatedAt`.
- App code uses `node:sqlite` (Node >= 22.5, `DatabaseSync`), experimental warning but works. Prefer `node:sqlite` over `sql.js` when possible.
- Domain `router.labkomgs.my.id` routing to 9router handled by `9router-domain-routing.md` skill.

## Workflow
1. **Verify container & DB state**
   - `docker ps --filter name=9router --format ...`
   - `docker exec 9router sh -c "node /tmp/dump-combos.cjs"` (needs script with `node:sqlite`)

2. **Backup before any write**
   - `docker exec 9router cp /app/data/db/data.sqlite /tmp/data.sqlite.backup`

3. **Dump / inspect (recommended: Node built-in `node:sqlite`, no external deps)**
   ```bash
   docker exec 9router sh -c '
   node --experimental-sqlite -e "
   const {DatabaseSync} = require(\"node:sqlite\");
   const db = new DatabaseSync(\"/app/data/db/data.sqlite\");
   const tables = db.prepare(\"SELECT name FROM sqlite_master WHERE type=\"table\" ORDER BY name\").all().map(r => r.name);
   console.log(\"TABLES: \" + JSON.stringify(tables));
   const schema = db.prepare(\"SELECT sql FROM sqlite_master WHERE type=\"table\" AND name=\"combos\"\").get();
   console.log(\"COMBOS SQL: \" + JSON.stringify(schema ? schema.sql : null));
   if (tables.indexOf(\"combos\") === -1) { console.log(\"Tabel combos tidak ada.\"); } else {
     const rows = db.prepare(\"SELECT id, name, kind, models, createdAt, updatedAt FROM combos\").all();
     console.log(\"COMBOS rows count: \" + rows.length);
     rows.forEach((r, i) => { console.log(\"--- row \" + i + \" ---\"); console.log(JSON.stringify(r, null, 2)); });
   }
   const meta = db.prepare(\"SELECT * FROM _meta\").all();
   if (meta.length) console.log(\"META: \" + JSON.stringify(meta));
   db.close();
   "
   ```

4. **Change**
   - Use SQLite via node:sqlite to UPDATE combos.

5. **Restart container**
   - `docker restart 9router`

6. **Verify**
   - `curl -s http://127.0.0.1:20128/api/health`
   - `curl -s http://127.0.0.1:20128/api/combos` (needs JWT auth)

## Key references (see references/)
- [references/combo-schema.md](references/combo-schema.md)
- [references/backup-restore.md](references/backup-restore.md)
- [references/verify-after-change.md](references/verify-after-change.md)
