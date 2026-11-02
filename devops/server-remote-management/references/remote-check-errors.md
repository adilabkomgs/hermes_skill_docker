# Remote Check Errors & Fixes

## Common Error Messages

### "No such file or directory"
- **Cause**: Path doesn't exist on target server
- **Fix**: 
  1. Verify user typed path correctly
  2. Run `find / -name "docker-backups" -type d 2>/dev/null` to locate folder
  3. Check alternative locations: `/opt/lampp/htdocs/`, `/var/www/html/`, `/home/user/`

### "ls: cannot access"
- **Cause**: User path `/opt/lampp/htdocs/script/docker-backups` doesn't exist
- **Evidence from session**: `ls: cannot access '/opt/lampp/htdocs/script/docker-backups': No such file or directory`

### "/usr/bin/bash: line 1: cd: No such file or directory"
- **Cause**: parent directory `/opt/lampp/htdocs/script` doesn't exist
- **Lesson**: Don't assume nested paths exist even if leaf folder should

## SSH Connection Issues

### Permission denied (publickey)
- User needs to set up SSH key auth or use password

### Connection refused
- Server may be down or SSH not running

### Timeout
- Network issue or firewall blocking port 22

## Decision Tree for Remote Checks

1. Verify path exists locally first (`ls -la /path`)
2. If remote: provide user manual SSH command
3. Don't wait for automated response when remote CLI not available
4. For multiple possible paths: suggest `find` command to explore