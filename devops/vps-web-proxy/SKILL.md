---
name: vps-web-proxy
description: Configure a domain URL on a VPS to route to a specific backend (Docker container port) via nginx reverse proxy, including HTTPS/SSL setup.
category: devops
created: 2026-11-19
updated: 2026-11-19
---

# VPS Web Proxy / Domain Routing

Setiap domain URL di VPS dipetakan ke backend tertentu (Docker container) via nginx reverse proxy, termasuk HTTPS/SSL.

## Trigger
- User ingin URL domain (contoh `9router.labkomgs.my.id`) diarahkan ke Docker container tertentu (port, misal `20128`).
- User ingin HTTPS/SSL aktif untuk domain tersebut.
- User ingin memisahkan traffic domain: satu domain ke aplikasi X, domain lain ke aplikasi Y.

## Langkah
1. Tentukan container target & port: `docker ps --filter name=<name> --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'`.
2. Tentukan domain yang dipakai (contoh `9router.labkomgs.my.id`).
3. Buat file konfigurasi nginx di `/etc/nginx/sites-available/<name>` dengan:
   - `server_name <domain>;`
   - `location / { proxy_pass http://127.0.0.1:<hostport>; ... }`
4. Aktifkan: `sudo ln -sf /etc/nginx/sites-available/<name> /etc/nginx/sites-enabled/`
5. Validasi & reload: `sudo nginx -t && sudo nginx -s reload`
6. (HTTPS) Pastikan cert valid & bisa dibaca ngix; `sudo nginx -t`; `sudo systemctl reload nginx` atau `sudo nginx -s reload`.

## Info penting
- DNS: buat **A record** domain -> IP VPS (`38.47.85.105`).
- `listen 80` untuk HTTP; `listen 443 ssl` untuk HTTPS.
- `proxy_set_header Upgrade $http_upgrade; Connection "upgrade";` untuk WebSocket/gRPC streaming.
- Container dalam bridge network umum butuh akses via port host yang ter-exposed: `http://127.0.0.1:<hostport>`.
- Host nginx yang berjalan di VPS (bukan container) yang mengontrol routing domain ke container.

## Bahasa
- Balas dalam Bahasa Indonesia kecuali user secara eksplisit bilang Inggris.

## Metode laporan
- Ringkas: tabel kecil / nilai utama dulu, bacaan panjang hanya kalau diminta.

## Pitfalls
- Nginx `sites-enabled` dipakai **symlink**, bukan copy—menghindari duplikasi file.
- SSL cert Let's Encrypt di `/etc/letsencrypt/` biasanya owner `root`; nginx yang dijalankan root tetap bisa baca, tapi `nginx -t`/cron dijalankan non-root akan gagal `Permission denied`. Fix: `sudo chmod -R a+rX /etc/letsencrypt/live/<domain> /etc/letsencrypt/archive/<domain>`.
- Server block host (`sites-available/9router`) yang proxy ke 9router harus di-**hapus/disable** kalau ingin domain lain mahasiswa proxy ke backend berbeda.
