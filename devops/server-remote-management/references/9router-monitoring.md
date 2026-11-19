# 9router Model Failure Monitoring + Telegram Alerts

## Overview
Automated monitoring script that checks 9router container logs for model failures (unavailable, quota exceeded, payment required) and sends Telegram alerts. Runs via cron every 10 minutes.

## Script Location
- **Script**: `/home/adilabkomgs/monitor-9router.sh`
- **Log**: `/home/adilabkomgs/9router-monitor.log`
- **Cron**: `*/10 * * * * /home/adilabkomgs/monitor-9router.sh`

## Monitored Error Patterns
- `unavailable` — Model is unavailable
- `quota.exceeded` / `402` — Quota exceeded / Payment required
- `403` — Access denied
- `payment.required` — Payment required
- `model.not.found` — Model not found
- `access.denied` — Access denied

## Alert Conditions
1. **Model failures detected** — Lists each failed model with error count
2. **Container down** — 9router container not running

## Telegram Bot Configuration
- **Bot**: `@aiserver01_bot` (ID: 8743677331)
- **Chat**: `8849806338` (Adi Santoso)
- **Format**: HTML with code blocks for model names

## Manual Commands
```bash
# Run manually (test)
/home/adilabkomgs/monitor-9router.sh

# View monitor log
cat /home/adilabkomgs/9router-monitor.log

# View cron
crontab -l

# Remove cron
crontab -r
```

## Sample Alert Output
```
🚨 9router Model Failures - 2026-11-13 14:32

Model gagal terdeteksi (10 menit terakhir):
• openrouter/nvidia/nemotron-3.5-super-vl:free → 47x error
• openrouter/thinkingmachines/inkling-2-small:free → 12x error

Combo saat ini masih mengandung model di atas.
Jalankan manual update combo jika perlu.
```

## Future Enhancement: Auto-Update Combo
Could extend script to auto-remove failed models from `9router-combo` in SQLite database:
```bash
docker exec 9router node -e "
const db = require('better-sqlite3')('/app/data/db/data.sqlite');
// Update combo models array, removing failed ones
"
```