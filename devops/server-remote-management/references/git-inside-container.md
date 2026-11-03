# Git Operations Inside Docker Containers

## Common Pitfalls

### 1. Git config identity required
Even as root, Git may refuse to commit if `user.email` and `user.name` are not set.
Fix:
```bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

### 2. SSH push blocked: no private key in container
A container may have `known_hosts` but lack the private key needed for `git@github.com` auth.
Symptoms:
```
Host key verification failed.
Permission denied (publickey).
```
Workarounds:
- Use HTTPS + Personal Access Token (PAT) instead of SSH remote URL.
- Mount host SSH agent or keys into the container at runtime.
- Rebuild image with required keys baked in (less secure).

### 3. dpkg lock-frontend permission denied
`docker exec <container> apt-get install ...` can fail with:
```
E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
```
Even when `whoami` shows root. Causes include read-only filesystem layers or restricted dpkg state.
Workarounds:
- Rebuild image with the package preinstalled.
- Use a temporary helper container with volume mounts to perform package installs on shared data instead.

### 4. Container OS detection
Different containers use different package managers:
- Alpine: `apk add`
- Debian/Ubuntu: `apt-get update && apt-get install -y`
Detect with:
```bash
docker exec <container> cat /etc/os-release
```

### 5. Non-interactive menu scripts
For bash menu scripts inside containers:
```bash
ssh user@host "docker exec <container> bash -lc 'cd /path && echo \"N\" | bash script.sh'"
```
Always prefix with `TERM=xterm` if the script uses `clear`/`read`:
```bash
ssh user@host "TERM=xterm docker exec <container> bash -lc 'echo \"1\" | bash /path/script.sh'"
```
