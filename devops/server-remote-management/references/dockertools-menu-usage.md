# dockertools.sh Menu Execution Reference

## Script Location
`/home/adilabkomgs/dockertools.sh`

## Menu Options
| No | Function | Description |
|----|----------|-------------|
| 1 | Show Docker | List containers, images, volumes |
| 2 | Show Backups | List available backup directories |
| 3 | Backup Container | Interactive container backup |
| 4 | Restore Container | Interactive container restore |
| 5 | Stop Container | Stop selected container |
| 6 | Restart Container | Restart selected container |
| 0 | Exit | Quit the program |

## Non-Interactive Execution
For automated or single-option runs:

```bash
# Run option 1 (show Docker)
TERM=xterm bash -c "echo '1' | bash /home/adilabkomgs/dockertools.sh"

# Run option 2 (show backups)  
TERM=xterm bash -c "echo '2' | bash /home/adilabkomgs/dockertools.sh"

# Run option 4 (restore)
TERM=xterm bash -c "echo '4' | bash /home/adilabkomgs/dockertools.sh"
```

**Important**: `TERM=xterm` must be set to avoid "TERM environment variable not set" error.

## Output Parsing Example
Extract container info from option 1 output:
```bash
output=$(TERM=xterm bash -c "echo '1' | bash dockertools.sh 2>/dev/null")

# Get running containers
running=$(echo "$output" | grep "Up.*hours\|Up.*days" | awk '{print $1, $2}')

# Get port mappings
ports=$(echo "$output" | grep "→" | awk '{print $2, $NF}')
```

## Common Use Cases

### Quick Status Check on Remote VPS
```bash
TERM=xterm bash -c "echo '1' | bash dockertools.sh" 2>/dev/null | grep -A 50 'Container yang SEDANG BERJALAN'
```

### List Available Backups
```bash
TERM=xterm bash -c "echo '2' | bash dockertools.sh" 2>/dev/null | grep -E '^\s+[0-9]+\s+'
```

### Verify Backup Contents Remotely
```bash
ssh user@vps "ls -la /path/to/backup/{container.json,environment.json,container-image.tar,container-fs.tar,volumes.txt}"
```