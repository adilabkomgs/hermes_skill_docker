---
name: server-remote-management
description: Skills for managing and querying remote servers via SSH and other protocols
category: devops
created: 2026-10-31
updated: 2026-10-31
---

# Server Remote Management

## Overview
Skills for managing and querying remote servers via various protocols (SSH, remote CLI). Handles infrastructure verification, backup checks, and cross-machine operations.

## Trigger Conditions
- User mentions "cek mesin", "cek di server", "remote", "SSH ke", atau nama VPS
- User requests file/folder checks on remote systems
- Connection to external machines is needed

## Language Preference
**DEFAULT LANGUAGE: Indonesia** when user indicates preference with "gunakan bahasa indonesia" or similar. Switch to English only if user explicitly requests or switches mid-conversation.

## Core Workflow

### 1. Verify Access Method
- Check if user provides SSH credentials (hostname, username, IP)
- If no credentials given, ask for explicit permission before attempting any remote lookup
- Never read connected accounts silently - ask each time

### 2. Connection Process
1. Confirm connection details with user
2. State what you intend to look up and get consent
3. Provide manual SSH command for user reference
4. Wait for user to execute and report results

### 3. Remote File/Directory Checks
When checking paths like docker backups:
```bash
# Manual command user can run
ssh user@ip 'ls -la /path/to/check'

# Or for backup verification
ssh user@ip 'ls -la /path/to/docker-backups'
```

## Common Pitfalls
- **Path confusion**: User may specify wrong path structure. Always verify existence first with `ls -la` before deeper inspection.
- **Assumption of local access**: VPS checks often require user's manual SSH. Don't wait for automated response that won't happen.
- **LAMPP path variations**: Standard path is `/opt/lampp/htdocs/` but some installs use different locations. Verify with `find / -name "docker-backups" -type d 2>/dev/null` if initial path fails.
### SSH key setup sequence
- When connection fails with "No identities found", run: `ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -C "description"` then `ssh-copy-id -i /root/.ssh/id_ed25519.pub user@host`
- **Key generation parameters**: Use `-t ed25519` (fast, secure), `-C "purpose"` for identification
- Always verify key exists after generation: `ls -la /root/.ssh/id_ed25519*`

### Non-interactive Script Execution
- For menu-driven scripts (like dockertools.sh), use: `TERM=xterm bash -c "echo 'N' | bash script.sh"`
- Replace N with menu option number
- Always set `TERM=xterm` to avoid "TERM environment variable not set" error
- **Pattern: `docker ps --filter 'name=<container>' --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}...'`** for container-specific queries
- **Direct docker stats**: `docker stats <container> --no-stream` for resource usage

### Docker Container Status Checking
When user says "cek mesin container X":
```bash
docker ps --filter 'name=<name>' --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}'
```
- Filter by name to avoid noise
- Format output as table for readability
- Status shows uptime, port mappings

### SSH Key Setup Troubleshooting
- When connection fails with "No identities found", run: `ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -C "purpose"` then `ssh-copy-id -i /root/.ssh/id_ed25519.pub user@host`
- After key generation, verify: `ls -la ~/.ssh/id_ed25519*`
- **Warning**: `ssh-copy-id` may report "All keys were skipped because they already exist" if key is already installed; this is not an error.

### HTML/Web Data Extraction
- Avoid long shell pipelines with regex/quoting for web scraping; they often hit shell-escaping and scanner blocks.
- Safer pattern: `curl -sL -o /tmp/page.html <url>` then parse with Python in `execute_code` using `pathlib.Path.read_text()` and simple regex.
- For Wikipedia-style pages, the infobox template often contains structured data in JSON-like attributes; extract those with Python instead of fragile `grep`.

### Package Install Inside Running Container
- `docker exec <container> apt-get install ...` can fail with `dpkg lock-frontend` even as root if the container's filesystem is read-only or dpkg state is restricted.
- Do not assume container packages are mutable; if install fails, fallback to rebuilding the image with the needed tool baked in.

## VPS Health Thresholds
- Disk usage >= 80%: warn user and offer cleanup of old backups/logs.
- Load average near 0 with available RAM > 500MB: system is healthy.

## References
- `references/remote-check-errors.md` - Common error messages and troubleshooting guide
- `references/ssh-commands.md` - Ready-to-use SSH command templates (when added)
- `references/docker-backup-check.md` - Docker backup verification guide

## Templates
- `templates/ssh-check.sh` - Automated script for remote directory verification via SSH

## Support Scripts
Use `skill_manage(action='write_file', file_path='scripts/<name>.sh')` to add verification scripts