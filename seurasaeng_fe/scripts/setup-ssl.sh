#!/bin/bash
set -e

DOMAIN="${DOMAIN:-seurasaeng.site}"
EMAIL="${EMAIL:-admin@seurasaeng.site}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSL: $1"
}

# SSL 인증서 자동 설정
setup_ssl() {
    local cert_path="/etc/ssl/certs/server.crt"
    local key_path="/etc/ssl/private/server.key"
    
    log "Setting up SSL certificate for domain: $DOMAIN"
    
    # Let's Encrypt 시도
    if [ "$AUTO_SSL" = "true" ] && command -v certbot >/dev/null 2>&1; then
        log "Attempting Let's Encrypt certificate..."
        
        mkdir -p /var/www/certbot/.well-known/acme-challenge
        
        if certbot certonly \
            --webroot \
            --webroot-path=/var/www/certbot \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            --domains "$DOMAIN" \
            --keep-until-expiring 2>/dev/null; then
            
            log "Let's Encrypt certificate obtained successfully"
            
            # 인증서 링크 생성
            ln -sf "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$cert_path"
            ln -sf "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$key_path"
            
            chmod 644 "$cert_path"
            chmod 600 "$key_path"
            
            return 0
        else
            log "Let's Encrypt failed, using self-signed certificate"
        fi
    fi
    
    # 자체 서명 인증서 생성
    log "Generating self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key_path" \
        -out "$cert_path" \
        -subj "/C=KR/ST=Seoul/L=Seoul/O=Seurasaeng/CN=$DOMAIN"
    
    chmod 644 "$cert_path"
    chmod 600 "$key_path"
    
    log "Self-signed certificate generated"
}

# 인증서 유효성 검사
validate_certificates() {
    local cert_path="/etc/ssl/certs/server.crt"
    local key_path="/etc/ssl/private/server.key"
    
    if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
        if openssl x509 -in "$cert_path" -noout -checkend 86400 >/dev/null 2>&1; then
            log "SSL certificate is valid"
            return 0
        fi
    fi
    return 1
}

# 메인 실행
if ! validate_certificates; then
    setup_ssl
else
    log "Valid SSL certificate already exists"
fi

# Nginx 설정 테스트
if nginx -t 2>/dev/null; then
    log "Nginx configuration is valid"
else
    log "Nginx configuration error, regenerating certificates"
    setup_ssl
fi

log "SSL setup completed"