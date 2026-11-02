#!/bin/bash
# SSH Remote Check Script Template
# Usage: ./ssh-check.sh <host> <user> <path>

set -e

if [ $# -ne 3 ]; then
    echo "Usage: $0 <host> <username> <path>"
    echo "Example: $0 38.47.85.105 adilabkomgs /opt/lampp/htdocs/script/docker-backups"
    exit 1
fi

HOST=$1
USER=$2
PATH_TO_CHECK=$3

echo "Checking if $PATH_TO_CHECK exists on $USER@$HOST..."
ssh ${USER}@${HOST} "if [ -e '${PATH_TO_CHECK}' ]; then ls -la '${PATH_TO_CHECK}'; else echo 'Path not found: ${PATH_TO_CHECK}'; fi"

echo ""
echo "If path not found, try locating it:"
ssh ${USER}@${HOST} "find / -name 'docker-backups' -type d 2>/dev/null | head -10"