#!/bin/bash
set -e
DOMAIN="${DOMAIN:-seurasaeng.site}"
EMAIL="${EMAIL:-admin@seurasaeng.site}"
log() { echo "[$(date '+%H:%M:%S')] SSL: $1"; }

cert_path="/etc/ssl/certs/server.crt"
key_path="/etc/ssl/private/server.key"

log "🔐 Setting up SSL for $DOMAIN..."

# 권한 재설정
chown nginx:nginx /var/www/certbot/.well-known/acme-challenge 2>/dev/null || true
chmod 755 /var/www/certbot/.well-known/acme-challenge

# Let's Encrypt 시도
if [ "$AUTO_SSL" = "true" ] && command -v certbot >/dev/null 2>&1; then
    log "🌐 Trying Let's Encrypt..."
    
    if certbot certonly --webroot --webroot-path=/var/www/certbot --email "$EMAIL" --agree-tos --no-eff-email --non-interactive --domains "$DOMAIN" --keep-until-expiring --quiet 2>/dev/null; then
        log "✅ Let's Encrypt success"
        
        if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
            ln -sf "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$cert_path"
            ln -sf "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$key_path"
            chown nginx:nginx "$cert_path" "$key_path" 2>/dev/null || true
            chmod 644 "$cert_path" && chmod 600 "$key_path"
            log "✅ Let's Encrypt linked"
            return 0
        fi
    else
        log "⚠️ Let's Encrypt failed"
    fi
fi

# 자체 서명 인증서
log "🔧 Generating self-signed..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$key_path" -out "$cert_path" -subj "/C=KR/ST=Seoul/L=Seoul/O=Seurasaeng/CN=$DOMAIN" 2>/dev/null
chown nginx:nginx "$cert_path" "$key_path" 2>/dev/null || true
chmod 644 "$cert_path" && chmod 600 "$key_path"
log "✅ Self-signed ready"