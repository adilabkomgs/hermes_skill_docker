---
name: vps-container-health
description: VPS and Docker container health checks with disk, RAM, CPU, port, and container status reporting — for remote VPS (SSH) and local container environments.
category: devops
---

# VPS & Container Health Check

Diagnose a remote VPS (`docker ps`, `df`, `free`, `uptime`, `docker stats`) and report container status, disk pressure, and resource usage as a compact table.

## Trigger
- "cek kapasitas vps" / "cek container" / "status container" / "disk apa yang penuh"
- User asks for VPS health, Docker status, or server resource report

## Steps

### 1. Server node
```bash
uptime
cat /proc/loadavg
free -h
df -h /
nproc / cat /proc/cpuinfo | grep "model name" | head -1
```

### 2. Docker runtime
```bash
docker version 2>/dev/null | head -5
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
docker stats --no-stream 2>/dev/null
```

### 3. Disk pressure (Docker volumes/images, old backups)
```bash
docker system df
docker volume ls
du -sh /var/lib/docker/_data/* 2>/dev/null | sort -hr | head -10
```

### 4. Container-specific check
```bash
docker ps -a | grep -i "<container-name>"
```

## Output format
Report as compact Markdown table:

| Resource | Value | Status |
|---|---|---|
| CPU | 1 core Xeon Icelake | ✅ Beban ringan |
| RAM | 1.9 GiB | ⚠️ |
| Disk | 17/19 GiB (89%) | ❌ Hampir penuh |
| Containers | 7 total, 6 running | ✅ |

## Priority
- Disk >= 80% → **warn** and offer cleanup order: `container prune` → `image prune` → `volume prune` → `apt-get clean`. Always `du -sh` backups before rm.

## VoIP Container Notes (opencode-agent)
- Mount bind: `/opt/lampp/htdocs (host) -> /app/workspace (container)`
- To write files into the web root, write to `/app/workspace/web1/` **inside the container** or use `docker cp`.
- Write directly to `/opt/lampp/htdocs/web1/` from agent: fails with permissions.

## Related skills
- `server-remote-management` — SSH access, remote file ops, Git push auth
