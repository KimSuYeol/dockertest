#!/bin/bash
set -e
log() { echo "[$(date '+%H:%M:%S')] PERM: $1"; }

log "Setting up permissions..."
chown -R nginx:nginx /var/www/certbot /var/log/nginx /usr/share/nginx/html /etc/ssl 2>/dev/null || true
chmod -R 755 /var/www/certbot /usr/share/nginx/html
chmod 755 /etc/ssl/certs 2>/dev/null || true
chmod 700 /etc/ssl/private 2>/dev/null || true
mkdir -p /var/www/certbot/.well-known/acme-challenge /var/log/letsencrypt
chown nginx:nginx /var/www/certbot/.well-known/acme-challenge 2>/dev/null || true
chmod 755 /var/www/certbot/.well-known/acme-challenge /var/log/letsencrypt
log "✅ Permissions set"