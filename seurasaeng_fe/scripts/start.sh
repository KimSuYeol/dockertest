#!/bin/bash
set -e
DOMAIN="${DOMAIN:-seurasaeng.site}"
EMAIL="${EMAIL:-admin@seurasaeng.site}"
log() { echo "[$(date '+%H:%M:%S')] $1"; }

log "🚀 Starting with Auto-SSL..."
/scripts/init-permissions.sh
/scripts/setup-ssl.sh

if nginx -t 2>/dev/null; then
    log "✅ Nginx config valid"
else
    log "❌ Nginx config error, regenerating SSL"
    /scripts/setup-ssl.sh
fi

log "🌐 Starting Nginx..."
exec nginx -g "daemon off;"