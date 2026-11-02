# Docker Backup Verification Guide

## Backup Contents Checklist

| File | Purpose | Required for Restore |
|------|---------|---------------------|
| `container.json` | Full container config (binds, network, ports, restart) | ✅ Yes |
| `environment.json` | All environment variables | ✅ Yes |
| `container-image.tar` | Image import (`docker load`) | ✅ Yes |
| `container-fs.tar` | Container filesystem | ✅ Yes |
| `volumes.txt` | Volume mount mappings | ✅ Yes |
| `labels.json` | Compose metadata (project name, service, config hash) | Info |
| `docker-compose.yml` | **NOT included** - must be sourced separately | ❌ No |

## Recovery Procedure

1. **Identify image** from container.json or image.txt
2. **Load image**: `docker load -i container-image.tar`
3. **Run container** with extracted config:
   ```bash
   docker run --name hermes \
     -p 9119:9119 \
     -v $(cat volumes.txt | cut -d: -f1):$(cat volumes.txt | cut -d: -f3):rw \
     --network hermes-docker_default \
     -d <image-id>
   ```

## Key Notes

- **No manual config needed** if environment.json present
- **Compose file missing** - note location from labels.json:
  ```
  "com.docker.compose.project.working_dir": "/home/user/hermes-docker"
  "com.docker.compose.project.config_files": "/home/user/hermes-docker/docker-compose.yml"
  ```