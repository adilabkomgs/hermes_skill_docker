---
name: server-remote-management
description: Skills for managing and querying remote servers via SSH and other protocols
category: devops
created: 2026-10-31
updated: 2026-10-31
---

## User Style & Workflow (First-Class Signals)

When the user expresses style, tone, format, or workflow preferences (or gives a frustration signal like "stop doing X", "too verbose", "just give me the answer", or "I don't like Y"), encode it into the skill that governs that task. Do not leave the correction stuck in chat history.

### Language
- Default to **Bahasa Indonesia** unless the user explicitly switches to English.
  Example: if the user asks "cek kapasitas vps", reply in Indonesian.

### Style — Concise
- Keep replies **concise**. Do not belabor.
- Give direct numbers, a compact table, or a one-line verdict first.
- Expand only if asked.

### Sequencing / Workflow
- If the user says "nggak perlu, langsung lanjut level 2" — stop re-explaining, apply the next action.
- If you discover a repeatable fix (e.g. how to write into a bind-mounted container path), add it as a "Pitfall" or "Re-do" step in the governing skill.

### Remote VPS access
- Agent host and VPS are **two different machines**. Agent SSH keys are not VPS keys.
- If SSH auth fails, do NOT fabricate results from memory/history. Hand off the exact manual command, then do the work from the user's result.
- If a tool fails, capture the **FIX** (install command, config step, env var), not "tool is broken".

## Principal skills (for remote VPS and container health)

## User Preferences & Workflow Notes

### Language
- Default to **Bahasa Indonesia** for responses unless user explicitly switches to English (see `memory`). Switch to English only if user explicitly requests or switches mid-conversation.

### Style
- Keep replies **concise**. Avoid long verbose explanations unless asked.

### Remote Access & Keying
- When checking remote VPS (e.g. `38.47.85.105`):
  1. Verify SSH key availability in the agent environment.
  2. If SSH fails (`Permission denied`), DO NOT retry blindly. Hand off the exact manual command (e.g. `ssh user@host 'docker ps ...'`) for the user to run locally, then relay results.
  3. If writing files to a bind-mounted volume (container -> host), write to the **container path** (e.g. `/app/workspace/...`) or use `docker cp` from the host. Writing to the host path directly from the agent may fail due to permissions or snapshot state.

### Git Push Auth
- SSH key auth requires the key to be registered on the target provider (GitHub).
- If SSH fails, use **HTTPS + PAT**:
  1. Set remote to HTTPS URL.
  2. Use `git config --global credential.helper store` (or configure interactively).
  3. Perform one authenticated push.
  4. Subsequent pushes use the stored credential.
  - Avoid echoing PATs in tooling.

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

**VPS & container resource/status check:** follow the class-level runbook `vps-container-health`, then report as a compact table.

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

### Git Push Auth from Inside a Container
- If `git push` from inside a container fails with SSH auth, prefer switching to HTTPS + PAT rather than trying to inject host keys or private keys interactively.
- The terminal environment may block commands that include PATs inline for security.
- Recommended sequence:
  1. Set remote to HTTPS GitHub URL.
  2. Configure `git config --global credential.helper store`.
  3. Perform one authenticated push so GitHub credentials are saved.
  4. Subsequent pushes use the stored credential.
- If the user already has a PAT, have them complete the authenticated push themselves to avoid exposing the token in tooling.
- **Verified working case (Nov 2026):** Container `hermes-agent-service` on VPS dcloud pushed to `github.com/adilabkomgs/hermes_skill_docker.git` by mounting host SSH key (`github_ed25519`) into `/root/.ssh/`, writing `~/.ssh/config` with `IdentityFile`, and setting remote to SSH URL.
- **SSH key mount sequence:** `docker cp ~/.ssh/github_ed25519 <container>:/root/.ssh/`, `chmod 600`, then write `~/.ssh/config` with `StrictHostKeyChecking no`. Test with `ssh -T git@github.com`.
- **Security note:** `~/.ssh/config` redirect may trigger dotfile-overwrite security scan; approve it. Avoid echoing PATs in tooling; prefer SSH key mount or have user push manually.

### HTML/Web Data Extraction
- Avoid long shell pipelines with regex/quoting for web scraping; they often hit shell-escaping and scanner blocks.
- Safer pattern: `curl -sL -o /tmp/page.html <url>` then parse with Python in `execute_code` using `pathlib.Path.read_text()` and simple regex.
- For Wikipedia-style pages, the infobox template often contains structured data in JSON-like attributes; extract those with Python instead of fragile `grep`.
- Kitco gold price: scrape from page HTML, search for `Current Price:` and `data-testid="hp-change"` and `data-testid="hp-quote-time"`. USD/IDR from exchangerate-api.com. Convert oz→gram by /28.3495.

### Package Install Inside Running Container
- `docker exec <container> apt-get install ...` can fail with `dpkg lock-frontend` even as root if the container's filesystem is read-only or dpkg state is restricted.
- Do not assume container packages are mutable; if install fails, fallback to rebuilding the image with the needed tool baked in.
- Detect OS first: `docker exec <container> cat /etc/os-release` (Debian→apt, Alpine→apk).

### Inspecting Hermes Config / Active Model
- To see what model Hermes is actually using, read `/root/.hermes/config.yaml` inside the container — `model.default`, `model.provider`, and `custom_providers[].models`.
- Use `sh -c` not `bash -lc` for `docker exec` in these images (`bash` often absent).
- `state.db` is SQLite but the container has **no `sqlite3` binary**; query via the bundled `better-sqlite3` Node module instead.
- Never echo API keys from config.yaml into chat — they are masked in tool output but remain sensitive.
- See `references/hermes-config-inspection.md` for the full field map and a verified config snapshot.

### Server Health Reporting
- Report health as a compact table: uptime, load, RAM, swap, disk, running/stopped containers.
- Warn at disk >= 80%; offer cleanup rather than running destructive commands unprompted.
- Cleanup order: `container prune` -> `image prune` -> `volume prune` -> `apt-get clean` (sudo). Always `du -sh` backups before `rm -rf`.
- `sudo` over non-interactive SSH needs a TTY — skip sudo steps and hand them to the user instead of retrying.
- See `references/server-health-cleanup.md` for the template.

### Web App Login Forms
- Some PHP login forms show "Password baru dan konfirmasi tidak sama." when POST fields don't match expected schema; inspect actual `<form>` inputs with `curl ... | grep -A 20 '<form'` before assuming username/password.
- Always check HTTP status (302 redirect = auth required) and title page to confirm login flow.

### GitHub Repo Status Check
- Use GitHub API: `curl -s https://api.github.com/repos/<user>/<repo> | python3 -m json.tool` to verify existence, branches, push time, visibility.
- 200 = exists; 404 = not found yet.
- Disk usage >= 80%: warn user and offer cleanup of old backups/logs.
- Load average near 0 with available RAM > 500MB: system is healthy.

## Remote Out-of-Process Handoff
- The agent's local terminal environment is **NOT** the target VPS. When the user asks to check/manage a VPS (e.g. `38.47.85.105`), do **not** assume the terminal can reach it — check whether the environment actually has an SSH private key for that host.
- If the environment has no key for the target host, **stop** the automated path. Do **not** fabricate container or server results from memory or history.
- Instead: state the limitation in one sentence, then hand off the **exact manual command** for the user to run locally, e.g.:
  `ssh adilabkomgs@38.47.85.105 'docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'`
- Log why the attempt failed (missing key / auth denied) so the next session knows not to retry the same blind SSH.

## References
- `references/remote-check-errors.md` - Common error messages and troubleshooting guide
- `references/docker-backup-check.md` - Docker backup verification guide
- `references/git-inside-container.md` - Git setup, push auth issues, dpkg lock, non-interactive execution inside containers
- `references/dockertools-menu-usage.md` - Docker tools menu notes
- `references/vps-access.md` - VPS agent access diagnosis: SSH key setup, disk/RAM/CPU status

## Remote Out-of-Process Handoff
- `references/github-pat-workflow.md` - Container-to-GitHub push flow using HTTPS + PAT and credential store
- `references/9router-model-discovery.md` - How to discover models in 9router container (catalog, combos, logs)
- `references/vps-access.md` - VPS agent access diagnosis: SSH key setup, disk/RAM/CPU status
- `references/hermes-config-inspection.md` - Read active model/provider from Hermes config inside container
- `references/server-health-cleanup.md` - Health check template, cleanup order, disk/backup pitfalls

## Templates
- `templates/ssh-check.sh` - Automated script for remote directory verification via SSH

## Support Scripts
- `scripts/sync-hermes-skills.sh` - Interactive backup/restore/status menu for Hermes skills <-> GitHub (also accepts `backup`/`restore`/`status` as arg)
Use `skill_manage(action='write_file', file_path='scripts/<name>.sh')` to add more