#!/usr/bin/env bash
# ============================================================
# Hermes Skills <-> GitHub Sync
# ============================================================
# Menu-driven script to backup/restore Hermes skills to/from a
# GitHub repo. Works from inside the Hermes container or any
# machine with ~/.hermes/skills/ mounted.
#
# Usage:
#   ./sync-hermes-skills.sh          # interactive menu
#   ./sync-hermes-skills.sh backup   # one-shot backup
#   ./sync-hermes-skills.sh status   # show git status
#
# Prerequisites:
#   - git installed
#   - SSH key mounted at ~/.ssh/github_ed25519 (or set remote to HTTPS+PAT)
#   - ~/.ssh/config with IdentityFile pointing at that key
# ============================================================
set -Eeuo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

REPO_URL="${HERMES_SKILLS_GIT_URL:-git@github.com:adilabkomgs/hermes_skill_docker.git}"
BACKUP_DIR="${HERMES_BACKUP_DIR:-$HOME/.hermes/skills}"

say()  { printf '%b\n' "${GREEN}[INFO]${NC} $*"; }
warn() { printf '%b\n' "${YELLOW}[WARN]${NC} $*"; }
err()  { printf '%b\n' "${RED}[ERROR]${NC} $*" >&2; }
pause() { printf '\n%bTekan Enter...%b' "$YELLOW" "$NC"; read -r _; }
header() { clear 2>/dev/null || true; printf '%b%s%b\n' "$BOLD" "$1" "$NC"; printf '%b%s%b\n' "$BLUE" "==========" "$NC"; }

check_prereq() {
  command -v git &>/dev/null || { err "git tidak ditemukan"; exit 1; }
  [[ -d "$BACKUP_DIR" ]] || { err "Folder skills tidak ada: $BACKUP_DIR"; exit 1; }
}

init_repo() {
  if [[ -d "$BACKUP_DIR/.git" ]]; then say "Repo git sudah ada"; return 0; fi
  cd "$BACKUP_DIR"
  git init -q
  git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"
  [[ -f .gitignore ]] || printf '%s\n' '*.key' '*.pem' '*.env' > .gitignore
  git add -A && git commit -qm "chore: initial skills backup" 2>/dev/null || true
  say "Repo diinisialisasi di $BACKUP_DIR"
}

backup() {
  header "BACKUP: Hermes Skills -> Git"
  check_prereq; cd "$BACKUP_DIR"; init_repo
  git add -A
  git diff --cached --quiet && { warn "Tidak ada perubahan."; pause; return; }
  git diff --cached --stat
  git commit -qm "sync: update skills [$(date '+%Y-%m-%d %H:%M:%S')]"
  say "Commit OK"
  # Try main then master (older repos default to master)
  if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
    say "Push OK"
  else
    warn "Push gagal — cek remote/key. Manual: git push origin master"
  fi
  pause
}

restore() {
  header "RESTORE: Git -> Hermes Skills"
  check_prereq; cd "$BACKUP_DIR"; init_repo
  git fetch origin 2>/dev/null || { err "fetch gagal"; pause; return; }
  local branch=main; git show-ref --verify --quiet refs/heads/$branch || branch=master
  echo ""; read -r -p "Timpa skills lokal dengan $branch? (y/N): " confirm
  [[ "${confirm,,}" =~ ^(y|yes)$ ]] || { warn "Dibatalkan."; pause; return; }
  git reset --hard "origin/$branch" && say "Restore OK"
  pause
}

status() {
  header "STATUS"
  check_prereq; cd "$BACKUP_DIR"; init_repo
  git remote -v
  echo "--- branch ---"; git branch -a
  echo "--- changes ---"; git status -s
  echo "--- last 5 ---"; git log --oneline -5
  pause
}

case "${1:-menu}" in
  backup)  backup ;;
  restore) restore ;;
  status)  status ;;
  *)
    while true; do
      header "Hermes Skills Git Sync"
      printf '  [1] Backup\n  [2] Restore\n  [3] Status\n  [0] Keluar\n\n'
      read -r -p "Pilih [0-3]: " c
      case "$c" in 1) backup;; 2) restore;; 3) status;; 0) exit 0;; *) warn "Pilihan salah.";; esac
    done
    ;;
esac
