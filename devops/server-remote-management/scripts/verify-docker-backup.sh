#!/bin/bash
# Automated Docker Backup Verification Script
# Usage: ./verify-docker-backup.sh user@hostname /path/to/backup

REMOTE_HOST="$1"
BACKUP_PATH="$2"

if [ -z "$REMOTE_HOST" ] || [ -z "$BACKUP_PATH" ]; then
    echo "Usage: $0 user@hostname /path/to/backup"
    exit 1
fi

echo "=== Docker Backup Verification ==="
echo "Host: $REMOTE_HOST"
echo "Path: $BACKUP_PATH"
echo ""

# Check backup directory
ssh "$REMOTE_HOST" "ls -la $BACKUP_PATH"

echo ""
echo "=== Backup Contents Check ==="

# Check for required files
for file in container.json environment.json container-image.tar container-fs.tar volumes.txt; do
    if ssh "$REMOTE_HOST" "test -f $BACKUP_PATH/$file"; then
        size=$(ssh "$REMOTE_HOST" "stat -c%s $BACKUP_PATH/$file 2>/dev/null || stat -f%z $BACKUP_PATH/$file 2>/dev/null")
        echo "✓ $file exists (${size} bytes)"
    else
        echo "✗ $file MISSING"
    fi
done

# Check for docker-compose.yml
if ssh "$REMOTE_HOST" "test -f $BACKUP_PATH/docker-compose.yml"; then
    echo "✓ docker-compose.yml included"
else
    echo "⚠ docker-compose.yml NOT IN BACKUP (common)"
    echo "  Must be sourced from labels.json metadata"
fi

echo ""
echo "=== Environment Variables ==="
if ssh "$REMOTE_HOST" "test -f $BACKUP_PATH/environment.json"; then
    ssh "$REMOTE_HOST" "cat $BACKUP_PATH/environment.json | python3 -c \"import json,sys; [print(f'  {k}={v}') for k,v in json.load(sys.stdin).items() if k not in ['PATH','LANG','GPG_KEY','PYTHON_VERSION','PYTHON_SHA256']] 2>/dev/null || cat $BACKUP_PATH/environment.json\""
fi