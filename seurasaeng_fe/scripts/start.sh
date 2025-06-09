#!/bin/bash
set -e

DOMAIN="${DOMAIN:-seurasaeng.site}"
EMAIL="${EMAIL:-admin@seurasaeng.site}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Seurasaeng Frontend with Auto-SSL..."

# SSL 인증서 설정 실행
/scripts/setup-ssl.sh

# 권한 설정
chown -R nginx:nginx /usr/share/nginx/html /var/log/nginx /var/www/certbot
chmod -R 755 /usr/share/nginx/html /var/www/certbot

log "Starting Nginx..."

# Nginx 시작
exec nginx -g "daemon off;"