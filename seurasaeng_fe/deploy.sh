#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수들
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 에러 발생시 스크립트 종료
set -e

# 배포 시작
log_info "🚀 HTTPS 지원 Frontend 배포를 시작합니다..."

# 현재 디렉토리 확인
cd /home/ubuntu

# 도메인 설정
DOMAIN="seurasaeng.site"
EMAIL="admin@seurasaeng.site"

# .env 파일 자동 생성 함수 (수정된 버전)
create_frontend_env() {
    log_info "프론트엔드 환경변수 파일을 확인합니다..."
    
    # 🔥 보안 설정 파일 안전하게 로드
    SECRETS_FILE="/etc/seurasaeng/frontend-secrets.env"
    
    # 기본값 설정
    VITE_MOBILITY_API_KEY="2868494a3053c4014954615d4dcfafc1"
    VITE_KAKAOMAP_API_KEY="d079914b9511e06b410311be64216366"
    VITE_PERPLEXITY_API_KEY="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"
    
    # 보안 설정 파일이 존재하고 읽을 수 있는 경우에만 로드
    if [ -f "$SECRETS_FILE" ] && [ -r "$SECRETS_FILE" ]; then
        log_info "보안 설정 파일을 로드합니다..."
        if source "$SECRETS_FILE" 2>/dev/null; then
            log_success "✅ 보안 설정 파일 로드 완료"
        else
            log_warning "⚠️ 보안 설정 파일 로드 실패, 기본값 사용"
        fi
    else
        log_warning "⚠️ 보안 설정 파일이 없거나 접근할 수 없습니다: $SECRETS_FILE"
        log_info "기본 API 키를 사용합니다."
    fi
    
    # .env 파일 생성 또는 업데이트
    if [ ! -f "seurasaeng_fe/.env" ]; then
        log_info ".env 파일을 생성합니다..."
    else
        log_info "기존 .env 파일을 업데이트합니다..."
    fi
    
    cat > seurasaeng_fe/.env << EOF
# API 서버 설정 (HTTPS 배포에 맞게 수정)
VITE_SOCKET_URL=wss://seurasaeng.site/ws
VITE_API_BASE_URL=https://seurasaeng.site/api

# 외부 API 키들
VITE_MOBILITY_API_KEY=${VITE_MOBILITY_API_KEY}
VITE_KAKAOMAP_API_KEY=${VITE_KAKAOMAP_API_KEY}
VITE_PERPLEXITY_API_KEY=${VITE_PERPLEXITY_API_KEY}

# 외부 API URL들
VITE_MOBILITY_API_BASE_URL=https://apis-navi.kakaomobility.com/v1/directions
VITE_KAKAOMAP_API_BASE_URL=//dapi.kakao.com/v2/maps/sdk.js
EOF
    
    # 파일 권한 설정
    chmod 600 seurasaeng_fe/.env
    
    log_success "✅ .env 파일 생성/업데이트 완료"
    
    # 환경변수 요약 출력 (값은 마스킹)
    log_info "=== 📋 프론트엔드 환경변수 설정 요약 ==="
    log_info "  VITE_SOCKET_URL: wss://seurasaeng.site/ws"
    log_info "  VITE_API_BASE_URL: https://seurasaeng.site/api"
    log_info "  VITE_MOBILITY_API_KEY: ${VITE_MOBILITY_API_KEY:0:8}***${VITE_MOBILITY_API_KEY: -4}"
    log_info "  VITE_KAKAOMAP_API_KEY: ${VITE_KAKAOMAP_API_KEY:0:8}***${VITE_KAKAOMAP_API_KEY: -4}"
    log_info "  VITE_PERPLEXITY_API_KEY: ${VITE_PERPLEXITY_API_KEY:0:8}***${VITE_PERPLEXITY_API_KEY: -4}"
    echo
}

# SSL 인증서 설정 함수 (간소화된 버전)
setup_ssl_certificates() {
    log_info "SSL 인증서를 설정합니다..."
    
    # Docker 볼륨 생성
    docker volume create certbot_conf 2>/dev/null || true
    docker volume create certbot_www 2>/dev/null || true
    
    # 기존 인증서 확인
    if docker run --rm \
        -v certbot_conf:/etc/letsencrypt \
        certbot/certbot:latest \
        certificates 2>/dev/null | grep -q "$DOMAIN"; then
        log_success "✅ 기존 SSL 인증서가 발견되었습니다."
        return 0
    fi
    
    log_info "새로운 SSL 인증서를 발급받습니다..."
    
    # 임시 Nginx 컨테이너로 80 포트 확보
    if docker ps | grep -q seuraseung-frontend; then
        log_info "기존 컨테이너를 임시 중지합니다..."
        cd seurasaeng_fe
        docker-compose down 2>/dev/null || true
        cd /home/ubuntu
    fi
    
    # Let's Encrypt 인증서 발급 (실패하면 자체 서명 인증서)
    if docker run --rm \
        -v certbot_conf:/etc/letsencrypt \
        -v certbot_www:/var/www/certbot \
        -p 80:80 \
        certbot/certbot:latest \
        certonly --standalone \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains "$DOMAIN" \
        --domains "www.$DOMAIN" 2>/dev/null; then
        log_success "✅ SSL 인증서 발급 완료"
    else
        log_warning "⚠️ SSL 인증서 발급 실패. 자체 서명 인증서를 사용합니다."
        
        # 인증서 디렉토리 생성
        docker run --rm -v certbot_conf:/etc/letsencrypt alpine \
            mkdir -p "/etc/letsencrypt/live/$DOMAIN"
        
        # 자체 서명 인증서 생성
        docker run --rm \
            -v certbot_conf:/etc/letsencrypt \
            alpine/openssl \
            req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
            -out "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
            -subj "/C=KR/ST=Seoul/L=Seoul/O=Seurasaeng/CN=$DOMAIN" 2>/dev/null
        
        # chain.pem 파일 생성
        docker run --rm \
            -v certbot_conf:/etc/letsencrypt \
            alpine \
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "/etc/letsencrypt/live/$DOMAIN/chain.pem"
        
        log_success "✅ 자체 서명 인증서 생성 완료"
    fi
}

# 환경변수 파일 자동 생성 실행
create_frontend_env

# 이전 배포 백업 (롤백 대비)
log_info "이전 배포 백업 중..."
if [ -f "seurasaeng_fe/docker-compose.yml.backup" ]; then
    rm -f "seurasaeng_fe/docker-compose.yml.backup.old" 2>/dev/null || true
    mv "seurasaeng_fe/docker-compose.yml.backup" "seurasaeng_fe/docker-compose.yml.backup.old" 2>/dev/null || true
fi
if [ -f "seurasaeng_fe/docker-compose.yml" ]; then
    cp "seurasaeng_fe/docker-compose.yml" "seurasaeng_fe/docker-compose.yml.backup"
fi

# Docker 이미지 로드
if [ -f "seurasaeng_fe-image.tar.gz" ]; then
    log_info "Docker 이미지를 로드합니다..."
    if docker load < seurasaeng_fe-image.tar.gz; then
        log_success "Docker 이미지 로드 완료"
        rm -f seurasaeng_fe-image.tar.gz
    else
        log_error "Docker 이미지 로드 실패"
        exit 1
    fi
else
    log_warning "seurasaeng_fe-image.tar.gz 파일이 없습니다. 새로 빌드합니다."
fi

# SSL 인증서 설정
setup_ssl_certificates

# 기존 컨테이너 graceful shutdown
log_info "기존 컨테이너들을 안전하게 중지합니다..."
if [ -f "seurasaeng_fe/docker-compose.yml" ]; then
    cd seurasaeng_fe
    if docker-compose ps -q 2>/dev/null | grep -q .; then
        # Nginx graceful shutdown
        if docker-compose ps frontend 2>/dev/null | grep -q "Up"; then
            log_info "Nginx 컨테이너에 graceful reload 신호를 전송합니다..."
            docker-compose exec -T frontend nginx -s quit 2>/dev/null || true
            sleep 3
        fi
        
        docker-compose down --remove-orphans --timeout 30 2>/dev/null || true
    else
        log_info "실행 중인 컨테이너가 없습니다."
    fi
    cd /home/ubuntu
else
    log_warning "docker-compose.yml 파일이 없습니다."
fi

# 사용하지 않는 이미지 정리
log_info "사용하지 않는 Docker 이미지를 정리합니다..."
docker image prune -f 2>/dev/null || true

# 로그 디렉토리 생성
mkdir -p /home/ubuntu/logs/nginx

# Nginx 설정 파일 확인
log_info "Nginx 설정을 확인합니다..."
if [ ! -d "seurasaeng_fe/nginx" ]; then
    log_error "Nginx 설정 파일이 없습니다."
    exit 1
fi

# Nginx 설정 파일 검증
if [ -f "seurasaeng_fe/nginx/nginx.conf" ] && [ -f "seurasaeng_fe/nginx/default.conf" ]; then
    log_success "✅ Nginx 설정 파일 확인 완료"
else
    log_error "❌ Nginx 설정 파일이 누락되었습니다."
    exit 1
fi

# 새 컨테이너 시작 (환경변수 포함 빌드)
log_info "새로운 컨테이너를 빌드하고 시작합니다..."
cd seurasaeng_fe

# 환경변수 로드 확인
log_info "환경변수 로드 확인..."
if [ -f ".env" ]; then
    set -a  # 자동으로 변수를 export
    source .env
    set +a
    log_success "✅ 환경변수 로드 완료"
else
    log_error "❌ .env 파일이 없습니다."
    exit 1
fi

# 이미지 빌드 (캐시 없이 새로 빌드하여 환경변수 적용)
log_info "Docker 이미지를 새로 빌드합니다 (환경변수 적용)..."
docker-compose build --no-cache

# 컨테이너 시작
docker-compose up -d
cd /home/ubuntu

# SSL 인증서 갱신 크론잡 설정 (간소화)
log_info "SSL 인증서 자동 갱신을 설정합니다..."
cat > /home/ubuntu/renew-ssl.sh << 'EOF'
#!/bin/bash
cd /home/ubuntu/seurasaeng_fe
docker-compose run --rm certbot renew --quiet 2>/dev/null
if [ $? -eq 0 ]; then
    docker-compose exec frontend nginx -s reload 2>/dev/null
    echo "$(date): SSL certificate renewed successfully" >> /home/ubuntu/ssl-renewal.log
fi
EOF
chmod +x /home/ubuntu/renew-ssl.sh

# 크론잡 설정 (매월 1일 오전 2시)
(crontab -l 2>/dev/null || echo "") | grep -v "renew-ssl.sh" | crontab -
(crontab -l 2>/dev/null; echo "0 2 1 * * /home/ubuntu/renew-ssl.sh") | crontab -

# 프론트엔드 헬스체크 (HTTPS 포함)
frontend_health_check() {
    local max_attempts=24  # 2분 대기 (5초 간격)
    local attempt=1
    
    log_info "프론트엔드 서비스 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        # 컨테이너 상태 확인
        if ! docker ps | grep seuraseung-frontend | grep -q "Up"; then
            log_warning "프론트엔드 컨테이너가 실행되지 않고 있습니다. ($attempt/$max_attempts)"
        else
            # HTTP 헬스체크
            if curl -f -s --connect-timeout 5 --max-time 10 http://localhost/health >/dev/null 2>&1; then
                log_success "✅ HTTP 헬스체크 통과"
                return 0
            fi
        fi
        
        log_info "프론트엔드 준비 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_error "프론트엔드 헬스체크 시간 초과"
    docker logs seuraseung-frontend --tail=50 2>/dev/null || true
    return 1
}

if ! frontend_health_check; then
    log_error "프론트엔드 서비스 시작 실패"
    
    # 컨테이너 상태 확인
    log_info "컨테이너 상태 확인..."
    cd seurasaeng_fe
    docker-compose ps 2>/dev/null || true
    
    # 로그 확인
    log_info "컨테이너 로그 확인..."
    docker-compose logs --tail=20 2>/dev/null || true
    
    cd /home/ubuntu
    exit 1
fi

# 백엔드 연결 테스트 (선택사항)
log_info "백엔드 서버 연결을 테스트합니다..."
BACKEND_IP="10.0.2.166"
BACKEND_PORT="8080"

if curl -f -s --connect-timeout 10 --max-time 30 http://${BACKEND_IP}:${BACKEND_PORT}/actuator/health >/dev/null 2>&1; then
    log_success "✅ 백엔드 서버 연결 정상"
    
    # API 프록시 테스트 (HTTP)
    log_info "HTTP API 프록시를 테스트합니다..."
    if curl -f -s --connect-timeout 10 --max-time 30 http://localhost/api/actuator/health >/dev/null 2>&1; then
        log_success "✅ HTTP API 프록시 정상 작동"
    else
        log_warning "⚠️ HTTP API 프록시 연결에 문제가 있을 수 있습니다."
    fi
    
    # HTTPS 테스트는 선택사항으로
    log_info "HTTPS API 프록시를 테스트합니다..."
    if curl -f -s -k --connect-timeout 10 --max-time 30 https://localhost/api/actuator/health >/dev/null 2>&1; then
        log_success "✅ HTTPS API 프록시 정상 작동"
    else
        log_warning "⚠️ HTTPS API 프록시는 SSL 설정 후 작동합니다."
    fi
else
    log_warning "⚠️ 백엔드 서버에 연결할 수 없습니다."
    log_info "백엔드 서버가 실행 중인지 확인해주세요: http://${BACKEND_IP}:${BACKEND_PORT}/actuator/health"
fi

# 배포 완료 메시지
log_success "🎉 HTTPS 지원 Frontend 배포가 완료되었습니다!"
echo
log_info "=== 🌐 서비스 접근 정보 ==="
log_info "🌐 HTTP 웹사이트: http://13.125.200.221"
log_info "🔒 HTTPS 웹사이트: https://$DOMAIN (SSL 설정 후)"
log_info "🔍 HTTP 헬스체크: http://13.125.200.221/health"
log_info "🔍 HTTPS 헬스체크: https://$DOMAIN/health (SSL 설정 후)"
if curl -f -s http://${BACKEND_IP}:${BACKEND_PORT}/actuator/health >/dev/null 2>&1; then
    log_info "🔗 HTTP API 프록시: http://13.125.200.221/api/actuator/health"
    log_info "🔗 HTTPS API 프록시: https://$DOMAIN/api/actuator/health (SSL 설정 후)"
fi
echo
log_info "=== 📊 관리 명령어 ==="
log_info "📊 서비스 상태 확인: cd seurasaeng_fe && docker-compose ps"
log_info "📋 로그 확인: cd seurasaeng_fe && docker-compose logs -f"
log_info "📋 Nginx 로그: docker logs seuraseung-frontend"

# 배포 정보 기록
{
    echo "$(date): HTTPS Frontend deployment completed successfully"
    echo "  - Frontend Health (HTTP): HEALTHY"
    echo "  - Environment Variables: LOADED"
    if curl -f -s http://${BACKEND_IP}:${BACKEND_PORT}/actuator/health >/dev/null 2>&1; then
        echo "  - Backend Connectivity: VERIFIED"
        echo "  - API Proxy (HTTP): $(curl -f -s http://localhost/api/actuator/health >/dev/null 2>&1 && echo "WORKING" || echo "FAILED")"
    else
        echo "  - Backend Connectivity: NOT_AVAILABLE"
    fi
    echo "  - Static Files: SERVING"
    echo "  - Port 80: BOUND"
} >> /home/ubuntu/deployment.log

log_success "🔒 HTTPS 지원 프론트엔드 배포가 완료되었습니다!"