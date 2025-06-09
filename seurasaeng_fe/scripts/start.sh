#!/bin/bash
set -e

DOMAIN="${DOMAIN:-seurasaeng.site}"
EMAIL="${EMAIL:-admin@seurasaeng.site}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] STARTUP: $1"
}

log "🚀 Starting Seurasaeng Frontend with Auto-SSL..."
log "Domain: $DOMAIN"
log "Email: $EMAIL"

# 권한 초기화
log "Setting up permissions..."
/scripts/init-permissions.sh

# SSL 인증서 설정
log "Setting up SSL certificates..."
/scripts/setup-ssl.sh

# Nginx 설정 테스트
if nginx -t 2>/dev/null; then
    log "✅ Nginx configuration is valid"
else
    log "❌ Nginx configuration error - regenerating SSL"
    /scripts/setup-ssl.sh
fi

log "🌐 Starting Nginx..."
exec nginx -g "daemon off;"