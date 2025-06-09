#!/bin/bash
set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PERMISSIONS: $1"
}

log "Initializing file permissions..."

# 디렉토리 소유권 설정
chown -R nginx:nginx \
    /var/www/certbot \
    /var/log/nginx \
    /usr/share/nginx/html \
    /etc/ssl

# 권한 설정
chmod -R 755 /var/www/certbot
chmod -R 755 /usr/share/nginx/html
chmod 755 /etc/ssl/certs
chmod 700 /etc/ssl/private

# acme-challenge 디렉토리 특별 권한
mkdir -p /var/www/certbot/.well-known/acme-challenge
chown nginx:nginx /var/www/certbot/.well-known/acme-challenge
chmod 755 /var/www/certbot/.well-known/acme-challenge

# 로그 디렉토리
mkdir -p /var/log/letsencrypt
chmod 755 /var/log/letsencrypt

log "✅ Permissions initialized"