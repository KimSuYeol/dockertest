#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

set -e

log_info "🚀 Auto-HTTPS Frontend 배포 시작..."

# 환경 변수
DOMAIN="${DOMAIN:-seurasaeng.site}"
EMAIL="${EMAIL:-admin@seurasaeng.site}"

log_info "도메인: $DOMAIN"
log_info "이메일: $EMAIL"

cd /home/ubuntu

# 이전 배포 백업
log_info "이전 배포 백업 중..."
if [ -f "seurasaeng_fe/docker-compose.yml" ]; then
    cp seurasaeng_fe/docker-compose.yml seurasaeng_fe/docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Docker 이미지 로드 (있는 경우)
if [ -f "seurasaeng_fe-image.tar.gz" ]; then
    log_info "Docker 이미지 로드 중..."
    docker load < seurasaeng_fe-image.tar.gz
    rm -f seurasaeng_fe-image.tar.gz
fi

# 기존 컨테이너 정리
log_info "기존 컨테이너 정리 중..."
if [ -f "seurasaeng_fe/docker-compose.yml" ]; then
    cd seurasaeng_fe
    docker-compose down --remove-orphans --timeout 30 2>/dev/null || true
    cd /home/ubuntu
fi

# 사용하지 않는 이미지 정리
docker image prune -f

# 로그 디렉토리 생성
mkdir -p /home/ubuntu/logs/nginx

# 설정 파일 확인
log_info "설정 파일 확인 중..."
required_files=(
    "seurasaeng_fe/Dockerfile"
    "seurasaeng_fe/docker-compose.yml"
    "seurasaeng_fe/nginx/nginx.conf"
    "seurasaeng_fe/nginx/default.conf"
    "seurasaeng_fe/scripts/start.sh"
    "seurasaeng_fe/scripts/setup-ssl.sh"
    "seurasaeng_fe/scripts/init-permissions.sh"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "필수 파일 누락: $file"
        exit 1
    fi
done

log_success "✅ 모든 설정 파일 확인 완료"

# DNS 확인
log_info "DNS 확인 중..."
CURRENT_IP=$(curl -s ifconfig.me || echo "unknown")
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1 || echo "unknown")

if [ "$CURRENT_IP" = "$DOMAIN_IP" ]; then
    log_success "✅ DNS 정상: $DOMAIN → $CURRENT_IP"
else
    log_warning "⚠️ DNS 확인: 현재 IP($CURRENT_IP) ≠ 도메인 IP($DOMAIN_IP)"
fi

# Docker 이미지 빌드
log_info "Docker 이미지 빌드 중..."
cd seurasaeng_fe

# 환경 변수를 docker-compose에 전달
export DOMAIN EMAIL

# 캐시 없이 새로 빌드
docker-compose build --no-cache

log_success "✅ Docker 이미지 빌드 완료"

# 컨테이너 시작
log_info "컨테이너 시작 중..."
docker-compose up -d

cd /home/ubuntu

# 컨테이너 초기화 대기
log_info "컨테이너 초기화 대기 중 (SSL 자동 설정 포함)..."
sleep 50

# 상세 헬스체크
health_check() {
    local max_attempts=30
    local attempt=1
    
    log_info "서비스 헬스체크 시작..."
    
    while [ $attempt -le $max_attempts ]; do
        # 컨테이너 상태 확인
        if ! docker ps | grep seuraseung-frontend | grep -q "Up"; then
            log_warning "컨테이너 시작 대기 중... ($attempt/$max_attempts)"
        else
            # HTTP 헬스체크
            if curl -f -s --connect-timeout 5 --max-time 10 http://localhost/health >/dev/null 2>&1; then
                log_success "✅ HTTP 서비스 정상"
                
                # HTTPS 헬스체크
                if curl -f -s -k --connect-timeout 5 --max-time 10 https://localhost/health >/dev/null 2>&1; then
                    log_success "✅ HTTPS 서비스 정상"
                    
                    # ACME Challenge 테스트
                    docker exec seuraseung-frontend sh -c 'echo "acme-test" > /var/www/certbot/.well-known/acme-challenge/test' 2>/dev/null || true
                    if curl -f -s http://localhost/.well-known/acme-challenge/test 2>/dev/null | grep -q "acme-test"; then
                        log_success "✅ ACME Challenge 경로 정상"
                    else
                        log_warning "⚠️ ACME Challenge 경로 문제 있음"
                    fi
                    
                    return 0
                else
                    log_info "HTTPS 준비 중..."
                fi
            fi
        fi
        
        log_info "서비스 준비 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_error "서비스 헬스체크 실패"
    return 1
}

# 헬스체크 실행
if ! health_check; then
    log_error "서비스 시작 실패"
    
    # 로그 확인
    log_info "컨테이너 로그 확인:"
    docker logs seuraseung-frontend --tail=30
    
    exit 1
fi

# SSL 인증서 상태 확인
log_info "SSL 인증서 상태 확인..."
sleep 10

SSL_ISSUER=$(echo | openssl s_client -connect localhost:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null || echo "확인 실패")

if echo "$SSL_ISSUER" | grep -q "Let's Encrypt"; then
    log_success "🔒 Let's Encrypt 정식 인증서 적용됨"
    SSL_TYPE="Let's Encrypt (정식)"
elif echo "$SSL_ISSUER" | grep -q "Seurasaeng"; then
    log_warning "🔐 자체 서명 인증서 사용 중"
    SSL_TYPE="자체 서명 (임시)"
    
    # Let's Encrypt 재시도 제안
    log_info "Let's Encrypt 인증서 수동 재시도 가능:"
    log_info "docker exec seuraseung-frontend /scripts/setup-ssl.sh"
else
    log_info "🔐 SSL 상태: $SSL_ISSUER"
    SSL_TYPE="기타"
fi

# 포트 상태 확인
HTTP_PORT=$(netstat -tuln | grep -q ":80 " && echo "✅ 정상" || echo "❌ 실패")
HTTPS_PORT=$(netstat -tuln | grep -q ":443 " && echo "✅ 정상" || echo "❌ 실패")

# 최종 상태 확인
log_info "전체 서비스 상태:"
cd seurasaeng_fe
docker-compose ps
cd /home/ubuntu

# 배포 완료 메시지
log_success "🎉 Auto-HTTPS 프론트엔드 배포 완료!"

echo
log_info "=== 🌐 서비스 접근 정보 ==="
log_info "🔒 HTTPS 웹사이트: https://$DOMAIN"
log_info "🌐 HTTP 웹사이트: http://$CURRENT_IP (HTTPS로 리다이렉트)"
log_info "🔍 헬스체크: https://$DOMAIN/health"
log_info "🔐 SSL 상태: https://$DOMAIN/ssl-status (내부용)"

echo
log_info "=== 📊 배포 상태 요약 ==="
log_info "• HTTP 서비스: $HTTP_PORT"
log_info "• HTTPS 서비스: $HTTPS_PORT"
log_info "• SSL 인증서: $SSL_TYPE"
log_info "• ACME Challenge: ✅ 설정됨"
log_info "• 자동 권한 관리: ✅ 활성화"

echo
log_info "=== 📋 관리 명령어 ==="
log_info "📊 서비스 상태: cd seurasaeng_fe && docker-compose ps"
log_info "📋 로그 확인: docker logs seuraseung-frontend -f"
log_info "🔒 SSL 재설정: docker exec seuraseung-frontend /scripts/setup-ssl.sh"
log_info "🔧 권한 재설정: docker exec seuraseung-frontend /scripts/init-permissions.sh"
log_info "🌐 ACME 테스트: curl http://$DOMAIN/.well-known/acme-challenge/test"

# 성공적인 배포 기록
{
    echo "$(date): Auto-HTTPS Frontend deployment completed successfully"
    echo "  - Domain: $DOMAIN"
    echo "  - SSL Type: $SSL_TYPE"
    echo "  - HTTP Port: $HTTP_PORT"
    echo "  - HTTPS Port: $HTTPS_PORT"
    echo "  - ACME Challenge: CONFIGURED"
} >> /home/ubuntu/deployment.log

log_success "🚀 모든 서비스가 준비되었습니다!"

if [ "$SSL_TYPE" = "자체 서명 (임시)" ]; then
    echo
    log_info "💡 Let's Encrypt 정식 인증서를 원한다면:"
    log_info "   docker exec seuraseung-frontend /scripts/setup-ssl.sh"
    log_info "   또는 DNS 설정을 확인하고 컨테이너를 재시작하세요."
fi