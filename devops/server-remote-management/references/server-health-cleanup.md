# Server Health & Cleanup

## Health Check Template
Run via SSH to a remote VPS to get one compact status report:
```bash
ssh user@host "echo '=== UPTIME ===' && uptime && echo '=== MEMORY ===' && free -h && \
echo '=== DISK ===' && df -h / && echo '=== LOAD ===' && cat /proc/loadavg && \
echo '=== DOCKER ===' && docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
```

## Interpretation
- Load average < 1.0 on a small VPS = healthy
- Available RAM > 500MB = comfortable
- Disk > 80% = warn and offer cleanup
- Container "Exited (130)" = stopped gracefully (usually Ctrl-C / SIGINT), not a crash

## Cleanup Sequence (safe order)
```bash
# 1. Remove stopped containers
docker container prune -f

# 2. Remove dangling images
docker image prune -f

# 3. Remove unused volumes
docker volume prune -f

# 4. apt cache (needs sudo)
sudo apt-get clean && sudo apt-get autoclean

# 5. Old docker backups — inspect BEFORE deleting
du -sh /opt/lampp/htdocs/script/docker-backups/* 2>/dev/null
```

## Pitfalls
- **`sudo` over non-interactive SSH fails**: `sudo: a terminal is required to read the password`. Either ask the user to run sudo commands themselves, or skip them.
- **`docker volume prune -f` deletes ALL unused volumes** — confirm nothing important is unmounted first.
- **Old backups are large**: `docker-backups/` can hold 1-2GB+ per container snapshot. Always `du -sh` before `rm -rf`.
- **Do NOT delete `opencode-vps` style containers without asking** — they may hold unsaved state even when stopped.

## Reporting
After cleanup, always show `df -h /` again so the user sees reclaimed space. If cleanup reclaimed <100MB, say so honestly rather than implying the disk is fixed.
