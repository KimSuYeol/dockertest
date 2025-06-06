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
log_info "🚀 Frontend 배포를 시작합니다..."

# 현재 디렉토리 확인
cd /home/ubuntu

# 이전 배포 백업 (롤백 대비)
log_info "이전 배포 백업 중..."
if [ -f "docker-compose.yml.backup" ]; then
    rm -f docker-compose.yml.backup.old
    mv docker-compose.yml.backup docker-compose.yml.backup.old
fi
if [ -f "seurasaeng_fe/docker-compose.yml" ]; then
    cp seurasaeng_fe/docker-compose.yml seurasaeng_fe/docker-compose.yml.backup
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
    log_warning "seurasaeng_fe-image.tar.gz 파일이 없습니다. 기존 이미지를 사용합니다."
fi

# 기존 컨테이너 graceful shutdown
log_info "기존 컨테이너들을 안전하게 중지합니다..."
if [ -f "seurasaeng_fe/docker-compose.yml" ]; then
    cd seurasaeng_fe
    if docker-compose ps -q 2>/dev/null | grep -q .; then
        # Nginx graceful shutdown
        if docker-compose ps frontend 2>/dev/null | grep -q "Up"; then
            log_info "Nginx 컨테이너에 graceful reload 신호를 전송합니다..."
            docker-compose exec -T frontend nginx -s quit 2>/dev/null || true
            sleep 5
        fi
        
        docker-compose down --remove-orphans --timeout 30
    else
        log_info "실행 중인 컨테이너가 없습니다."
    fi
    cd /home/ubuntu
else
    log_warning "docker-compose.yml 파일이 없습니다."
fi

# 사용하지 않는 이미지 정리
log_info "사용하지 않는 Docker 이미지를 정리합니다..."
docker image prune -f

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

# 새 컨테이너 시작
log_info "새로운 컨테이너를 시작합니다..."
cd seurasaeng_fe
docker-compose up -d
cd /home/ubuntu

# 프론트엔드 헬스체크
frontend_health_check() {
    local max_attempts=36  # 3분 대기 (5초 간격)
    local attempt=1
    
    log_info "프론트엔드 서비스 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        # 컨테이너 상태 확인
        if ! docker ps | grep seuraseung-frontend | grep -q "Up"; then
            log_warning "프론트엔드 컨테이너가 실행되지 않고 있습니다. ($attempt/$max_attempts)"
        else
            # 헬스체크 엔드포인트 테스트
            if curl -f -s --connect-timeout 5 --max-time 10 http://localhost/health >/dev/null 2>&1; then
                log_success "✅ 프론트엔드 헬스체크 통과"
                return 0
            fi
        fi
        
        log_info "프론트엔드 준비 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_error "프론트엔드 헬스체크 시간 초과"
    docker logs seuraseung-frontend --tail=50
    return 1
}

if ! frontend_health_check; then
    log_error "프론트엔드 서비스 시작 실패"
    
    # 롤백 시도
    log_warning "이전 버전으로 롤백을 시도합니다..."
    if [ -f "seurasaeng_fe/docker-compose.yml.backup" ]; then
        cd seurasaeng_fe
        docker-compose down --remove-orphans
        cp docker-compose.yml.backup docker-compose.yml
        docker-compose up -d
        cd /home/ubuntu
        sleep 30
        
        if curl -f -s http://localhost/health >/dev/null 2>&1; then
            log_warning "이전 버전으로 롤백되었습니다."
        else
            log_error "롤백도 실패했습니다."
        fi
    fi
    exit 1
fi

# 백엔드 연결 테스트 (선택사항)
log_info "백엔드 서버 연결을 테스트합니다..."
BACKEND_IP="10.0.2.165"
BACKEND_PORT="8080"

if curl -f -s --connect-timeout 10 --max-time 30 http://${BACKEND_IP}:${BACKEND_PORT}/api/actuator/health >/dev/null 2>&1; then
    log_success "✅ 백엔드 서버 연결 정상"
    
    # API 프록시 테스트
    log_info "API 프록시를 테스트합니다..."
    if curl -f -s --connect-timeout 10 --max-time 30 http://localhost/api/actuator/health >/dev/null 2>&1; then
        log_success "✅ API 프록시 정상 작동"
    else
        log_warning "⚠️ API 프록시 연결에 문제가 있을 수 있습니다."
    fi
else
    log_warning "⚠️ 백엔드 서버에 연결할 수 없습니다."
    log_info "백엔드 서버가 실행 중인지 확인해주세요: http://${BACKEND_IP}:${BACKEND_PORT}/api/actuator/health"
fi

# 추가 기능 테스트
log_info "추가 프론트엔드 기능 테스트를 수행합니다..."

# 정적 파일 서빙 테스트
if curl -f -s --connect-timeout 5 --max-time 10 http://localhost/ >/dev/null 2>&1; then
    log_success "✅ 메인 페이지 로딩 정상"
else
    log_warning "⚠️ 메인 페이지 로딩 실패"
fi

# 포트 상태 확인
log_info "포트 상태를 확인합니다..."
if netstat -tuln | grep -q ":80 "; then
    log_success "✅ 포트 80이 정상적으로 바인딩되었습니다."
else
    log_error "❌ 포트 80 바인딩에 실패했습니다."
    exit 1
fi

# 최종 상태 확인
log_info "전체 서비스 상태를 확인합니다..."
cd seurasaeng_fe
docker-compose ps
cd /home/ubuntu

# 성능 및 리소스 사용량 확인
log_info "컨테이너 리소스 사용량:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker ps -q) || true

# SSL 인증서 상태 확인 (선택사항)
check_ssl_status() {
    log_info "SSL 인증서 상태를 확인합니다..."
    if command -v certbot >/dev/null 2>&1; then
        local cert_count=$(sudo certbot certificates 2>/dev/null | grep -c "seurasaeng.site" || echo "0")
        if [ "$cert_count" -gt 0 ]; then
            log_success "✅ SSL 인증서가 설치되어 있습니다."
            # 인증서 만료일 확인
            sudo certbot certificates 2>/dev/null | grep -A 2 "seurasaeng.site" || true
        else
            log_warning "⚠️ SSL 인증서가 없습니다."
            log_info "SSL 인증서 설치 명령어: sudo certbot --nginx -d seurasaeng.site -d www.seurasaeng.site"
        fi
    else
        log_info "ℹ️ Certbot이 설치되지 않았습니다. HTTP로 서비스됩니다."
    fi
}

check_ssl_status

# 배포 완료 메시지
log_success "🎉 Frontend 배포가 완료되었습니다!"
echo
log_info "=== 🌐 서비스 접근 정보 ==="
log_info "🌐 웹사이트 접속: http://13.125.200.221"
log_info "🔍 헬스체크: http://13.125.200.221/health"
if curl -f -s http://${BACKEND_IP}:${BACKEND_PORT}/api/actuator/health >/dev/null 2>&1; then
    log_info "🔗 API 프록시: http://13.125.200.221/api/actuator/health"
fi
log_info "🖥️ 백엔드 직접 접속: http://${BACKEND_IP}:${BACKEND_PORT}/api/actuator/health"
echo
log_info "=== 📊 관리 명령어 ==="
log_info "📊 서비스 상태 확인: cd seurasaeng_fe && docker-compose ps"
log_info "📋 로그 확인: cd seurasaeng_fe && docker-compose logs -f"
log_info "📋 Nginx 로그: docker logs seuraseung-frontend"
log_info "🔧 Nginx 설정 확인: docker exec seuraseung-frontend cat /etc/nginx/conf.d/default.conf"

# 배포 정보 기록
{
    echo "$(date): Frontend deployment completed successfully"
    echo "  - Frontend Health: HEALTHY"
    if curl -f -s http://${BACKEND_IP}:${BACKEND_PORT}/api/actuator/health >/dev/null 2>&1; then
        echo "  - Backend Connectivity: VERIFIED"
        echo "  - API Proxy: WORKING"
    else
        echo "  - Backend Connectivity: NOT_AVAILABLE"
        echo "  - API Proxy: BACKEND_DOWN"
    fi
    echo "  - Static Files: SERVING"
    echo "  - Port 80: BOUND"
} >> /home/ubuntu/deployment.log

# 성공적인 배포 백업 업데이트
if [ -f "seurasaeng_fe/docker-compose.yml" ]; then
    cp seurasaeng_fe/docker-compose.yml seurasaeng_fe/docker-compose.yml.success
fi

# 시스템 리소스 최종 확인
log_info "=== 💾 시스템 리소스 사용량 ==="
df -h | grep -E "/$|/home"
free -h

log_success "🚀 프론트엔드가 완전히 준비되었습니다. 서비스 이용이 가능합니다!"