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
    
    log "🔐 Setting up SSL certificate for domain: $DOMAIN"
    
    # 권한 확인
    chown nginx:nginx /var/www/certbot/.well-known/acme-challenge
    chmod 755 /var/www/certbot/.well-known/acme-challenge
    
    # Let's Encrypt 시도
    if [ "$AUTO_SSL" = "true" ] && command -v certbot >/dev/null 2>&1; then
        log "🌐 Attempting Let's Encrypt certificate..."
        
        # 웹루트 방식으로 시도
        if su nginx -s /bin/sh -c "certbot certonly \
            --webroot \
            --webroot-path=/var/www/certbot \
            --email '$EMAIL' \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            --domains '$DOMAIN' \
            --keep-until-expiring \
            --quiet" 2>/dev/null; then
            
            log "✅ Let's Encrypt certificate obtained successfully"
            
            # 인증서 링크 생성
            if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
                ln -sf "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$cert_path"
                ln -sf "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$key_path"
                
                chown nginx:nginx "$cert_path" "$key_path"
                chmod 644 "$cert_path"
                chmod 600 "$key_path"
                
                log "✅ Let's Encrypt certificate linked successfully"
                return 0
            fi
        else
            log "⚠️ Let's Encrypt webroot method failed"
        fi
        
        # Standalone 방식 시도 (포트 80이 비어있을 때)
        log "🔄 Trying standalone method..."
        if ! netstat -tuln | grep -q ":80 "; then
            if certbot certonly \
                --standalone \
                --email "$EMAIL" \
                --agree-tos \
                --non-interactive \
                --domains "$DOMAIN" \
                --keep-until-expiring \
                --quiet 2>/dev/null; then
                
                log "✅ Let's Encrypt standalone certificate obtained"
                
                if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
                    ln -sf "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$cert_path"
                    ln -sf "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$key_path"
                    
                    chown nginx:nginx "$cert_path" "$key_path"
                    chmod 644 "$cert_path"
                    chmod 600 "$key_path"
                    
                    log "✅ Let's Encrypt standalone certificate linked"
                    return 0
                fi
            fi
        fi
        
        log "⚠️ Let's Encrypt failed, using self-signed certificate"
    fi
    
    # 자체 서명 인증서 생성
    log "🔧 Generating self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key_path" \
        -out "$cert_path" \
        -subj "/C=KR/ST=Seoul/L=Seoul/O=Seurasaeng/CN=$DOMAIN" \
        2>/dev/null
    
    chown nginx:nginx "$cert_path" "$key_path"
    chmod 644 "$cert_path"
    chmod 600 "$key_path"
    
    log "✅ Self-signed certificate generated"
}

# 인증서 유효성 검사
validate_certificates() {
    local cert_path="/etc/ssl/certs/server.crt"
    local key_path="/etc/ssl/private/server.key"
    
    if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
        if openssl x509 -in "$cert_path" -noout -checkend 86400 >/dev/null 2>&1; then
            log "✅ SSL certificate is valid"
            return 0
        fi
    fi
    return 1
}

# 메인 실행
main() {
    if ! validate_certificates; then
        setup_ssl
    else
        log "✅ Valid SSL certificate already exists"
    fi
    
    log "🔐 SSL setup completed"
}

main "$@"