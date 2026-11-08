# GitHub Push Workflow from Inside a Container

## When to use
- Git push from inside a container fails with `Permission denied (publickey)`
- Container lacks usable SSH private key for GitHub
- User prefers not to inject host keys interactively

## Recommended Sequence

### 1. Switch remote to HTTPS
```bash
git remote set-url origin https://github.com/username/repo.git
```

### 2. Configure credential helper
```bash
git config --global credential.helper store
```

### 3. Perform authenticated push once
Use one of:
- Manual push from inside the container and enter PAT when prompted for password
- If using Hermes, have the user run the push command themselves to avoid handling raw PATs in tooling

### 4. Verify
```bash
git remote -v
git log --oneline -3
git push origin master
```

## SSH Key Alternative (when HTTPS/PAT is not preferred)

### Mount host SSH key into container
```bash
docker cp ~/.ssh/github_ed25519 <container>:/root/.ssh/github_ed25519
docker cp ~/.ssh/github_ed25519.pub <container>:/root/.ssh/github_ed25519.pub
docker exec <container> bash -lc 'chmod 600 ~/.ssh/github_ed25519 && chmod 644 ~/.ssh/github_ed25519.pub'
```

### Configure SSH client
```bash
docker exec <container> bash -lc 'cat > ~/.ssh/config <<EOF
Host github.com
  IdentityFile ~/.ssh/github_ed25519
  StrictHostKeyChecking no
EOF
chmod 600 ~/.ssh/config'
```

### Verify auth
```bash
docker exec <container> bash -lc 'ssh -T git@github.com'
```

### Push using SSH
```bash
docker exec <container> bash -lc 'cd /path/to/repo && git remote set-url origin git@github.com:username/repo.git && git push origin master'
```

## Verified working case
- Host: VPS dcloud (adilabkomgs@38.47.85.105)
- Container: hermes-agent-service
- Repo: git@github.com:adilabkomgs/hermes_skill_docker.git
- Result: push succeeded after SSH key mounted and config written.
- Avoid inline PATs in shell commands; security tooling may block them.
- Stored credentials are kept in `~/.git-credentials` with mode 600.
- If the user provided a PAT earlier in conversation, do not echo it back; guide them to complete auth themselves.

## Fallbacks
- If HTTPS push still fails, verify the repo exists and the PAT has `repo` scope.
- As a last resort, mount host SSH agent or keys into the container, or rebuild the image with git and required keys baked in.
