# Git Push Authentication — Verified Pattern (Nov 2026)

## The problem
- **Fine-grained PAT cannot push** to a GitHub repo (HTTP 403). Verified.
- **Classic PAT (ghp_...) with `repo` scope** pushes successfully.
- SSH key auth works **only if** the key is registered on the target provider (GitHub). The agent's private key (`id_ed25519` → `hermes-docker`) was present but **not subscribed**, so SSH push was denied.

## Verified working case
- Repository: `adilabkomgs/hermes_skill_docker.git` (public, `master` branch)
- Classic PAT: `<REDACTED_PAT>`
- Result: `8a95193..c6ad5c7  master -> master` on 2026-11-19

## Recommended sequence (SSH auth fails)
1. Set remote to HTTPS URL:
   ```bash
   git remote set-url origin https://github.com/adilabkomgs/hermes_skill_docker.git
   ```
2. Configure credential store:
   ```bash
   git config credential.helper store
   ```
3. Push once (user completes the authenticated push to avoid exposing the token in tooling).
4. Subsequent pushes use the stored credential.

## Try before push
- Verify repo is accessible via GitHub API:
   ```bash
   curl -s https://api.github.com/repos/adilabkomgs/hermes_skill_docker | python3 -m json.tool
   ```
   - 200 = exists; 404 = not found.
