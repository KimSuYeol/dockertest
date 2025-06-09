#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

log "🚀 Starting Auto-HTTPS deployment..."

# 현재 디렉토리에서 작업 (GitHub Actions에서 복사된 위치)
WORK_DIR=$(pwd)
log "Working directory: $WORK_DIR"

# 파일 존재 확인
if [ ! -f "Dockerfile" ]; then
    error "Dockerfile not found in $WORK_DIR"
    ls -la
    exit 1
fi

# 기존 컨테이너 정리
log "Cleaning up existing containers..."
docker-compose down --remove-orphans 2>/dev/null || true
docker system prune -f

# 이미지 빌드
log "Building Docker image..."
docker-compose build --no-cache

# 컨테이너 시작
log "Starting containers..."
docker-compose up -d

# 헬스체크
log "Waiting for service to be ready..."
sleep 60

for i in {1..20}; do
    if curl -f -s http://localhost/health >/dev/null 2>&1; then
        success "✅ HTTP service is ready"
        break
    fi
    log "Waiting... ($i/20)"
    sleep 10
done

# HTTPS 체크
sleep 30
if curl -f -s -k https://localhost/health >/dev/null 2>&1; then
    success "✅ HTTPS service is ready"
    
    # SSL 인증서 타입 확인
    SSL_ISSUER=$(echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null || echo "unknown")
    if echo "$SSL_ISSUER" | grep -q "Let's Encrypt"; then
        success "🔒 Let's Encrypt certificate active"
    else
        log "🔐 Self-signed certificate active (Let's Encrypt will retry)"
    fi
else
    log "⚠️ HTTPS not ready yet, but HTTP is working"
fi

# 상태 확인
log "Final status:"
docker-compose ps
docker logs seuraseung-frontend --tail=10

success "🎉 Deployment completed!"
log "🌐 Access: https://seurasaeng.site"
log "🔍 Health: https://seurasaeng.site/health"