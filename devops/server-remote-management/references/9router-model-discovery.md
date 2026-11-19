# 9router Model Discovery

## Overview
How to discover what models are configured and actively running in a 9router container on a remote VPS.

## Key Files in 9router Container
- `/app/data/model-catalog.json` — Full catalog of all available models (5769+ models from 26 providers)
- `/app/data/model-catalog-raw.json` — Raw provider data
- `/app/data/db/data.sqlite` — SQLite database with combos, usage history, request details

## Discovery Commands

### List All Available Models (from catalog)
```bash
docker exec 9router cat /app/data/model-catalog.json | jq '.models | keys'
```

### Filter for Specific Provider (e.g., opencode)
```bash
docker exec 9router cat /app/data/model-catalog.json | jq '.models | keys' | grep opencode
```

### Check Active Combo Configuration
```bash
docker exec 9router node -e "const db = require('better-sqlite3')('/app/data/db/data.sqlite'); const rows = db.prepare('SELECT name, kind, models FROM combos').all(); console.log(JSON.stringify(rows, null, 2));"
```

### Check Recent Request Logs (see which models are actually being used)
```bash
docker logs 9router 2>&1 | head -100
```

### Check Container Health
```bash
# curl is NOT available in the container, use wget instead
docker exec 9router wget -qO- http://localhost:20128/api/health 2>/dev/null || echo "Health endpoint not exposed"
```

## Model ID Format
Models use prefix format: `<provider>/<model-name>`
- `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free`
- `opencode/deepseek-v4.1-flash-free`
- `oc/nemotron-3.5-super-vl-free` (alias for opencode)
- `ps/poolside/laguna-s-2.1` (poolside)
- `gemini/gemini-3.8-flash`
- `mmf/mimo-auto`

## Combo Strategy
- Combo `9router-combo` uses **fallback** strategy (round-robin per logs)
- Models tried in order until one succeeds
- Current active model depends on which one last succeeded

## Common Issues
- Some opencode models return 400 "Model is unavailable" (muse-spark, union-alpha)
- Gemini 3.8-flash showing 503 "high demand"
- Deepseek-v4.1-flash-free working reliably
- **Log noise**: Frequent `TypeError: Failed to parse body as FormData` errors from malformed requests
- **Catalog sync**: May show `[modelCatalog] sync failed: fetch failed` in logs

## Verified Combo Configuration (Nov 2026)
Active combo `9router-combo` with 9 models in fallback order:
1. `openrouter/nvidia/nemotron-3.5-super-vl:free`
2. `openrouter/openrouter/free`
3. `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free`
4. `openrouter/thinkingmachines/inkling-2-small:free`
5. `mmf/mimo-auto`
6. `oc/nemotron-3.5-super-vl-free`
7. `ps/poolside/laguna-s-2.1`
8. `ps/poolside/laguna-xs-2.1`
9. `gemini/gemini-3.8-flash`

## Verification
After discovering models, check container health:
```bash
docker exec 9router wget -qO- http://localhost:20128/api/health 2>/dev/null || echo "Health endpoint not exposed"
```