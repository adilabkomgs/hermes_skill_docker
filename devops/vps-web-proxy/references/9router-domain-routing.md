# 9router Domain Routing Reference

## Context
9router (`decolua/9router:latest`) adalah Next.js web dashboard, bukan reverse proxy biasa.
Container berjalan di bridge network dengan port host yang exposed: `0.0.0.0:20128 -> 20128/tcp`.

## Container Detail
- Image: `decolua/9router:latest` (v0.5.112)
- CMD: `node` (Next.js standalone)
- Port: `20128`
- Data: `/app/data` (volume `9router-docker_9router_data`)
- Config di-host: `/etc/nginx/sites-available/9router` (host nginx, PID 3169720)

## Langkah Konfigurasi
1. DNS: A record `<domain>` -> `38.47.85.105`
2. Nginx site: `/etc/nginx/sites-available/<domain>`
3. Aktifkan symlink di `/etc/nginx/sites-enabled/`
4. `sudo nginx -t && sudo nginx -s reload`

## Nginx Config Snippet
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name <domain>;

    location / {
        proxy_pass http://127.0.0.1:20128;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering off;
        proxy_read_timeout 300s;
    }
}
```

## HTTPS / SSL
- Cert Let's Encrypt milik `38.47.85.105` ada di `/etc/letsencrypt/live/38.47.85.105/`.
- Fitur `listen 443 ssl` mengharuskan file cert bisa dibaca ngix.
- Pitfall: `/etc/letsencrypt` biasanya owner `root`. `nginx -t` yang dijalankan non-root
  gagal `Permission denied`. Fix: `sudo chmod -R a+rX /etc/letsencrypt/live/<domain>
  /etc/letsencrypt/archive/<domain>`.

## Catatan
- Host nginx (bukan container 9router) yang mengontrol routing domain ke container.
- Hapus/disable symlink `sites-enabled/9router` yang proxy ke `127.0.0.1:20128`
  jika domain khusus 9router ingin diganti dengan domain lain ke backend berbeda.
