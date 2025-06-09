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
log_info "🚀 Spring Boot Backend 배포를 시작합니다..."

# 현재 디렉토리 확인
cd /home/ubuntu

# 이전 배포 백업
log_info "이전 배포 백업 중..."
if [ -f "seurasaeng_be/docker-compose.yml.backup" ]; then
    mv seurasaeng_be/docker-compose.yml.backup seurasaeng_be/docker-compose.yml.backup.old
fi
if [ -f "seurasaeng_be/docker-compose.yml" ]; then
    cp seurasaeng_be/docker-compose.yml seurasaeng_be/docker-compose.yml.backup
fi

# Docker 이미지 로드
if [ -f "seurasaeng_be-image.tar.gz" ]; then
    log_info "Docker 이미지를 로드합니다..."
    if docker load < seurasaeng_be-image.tar.gz; then
        log_success "Docker 이미지 로드 완료"
        rm -f seurasaeng_be-image.tar.gz
    else
        log_error "Docker 이미지 로드 실패"
        exit 1
    fi
else
    log_warning "Docker 이미지 파일이 없습니다. 기존 이미지를 사용합니다."
fi

# 기존 컨테이너 중지
log_info "기존 컨테이너들을 중지합니다..."
if [ -f "seurasaeng_be/docker-compose.yml" ]; then
    cd seurasaeng_be
    if docker-compose ps -q 2>/dev/null | grep -q .; then
        docker-compose down --remove-orphans --timeout 60
    else
        log_info "실행 중인 컨테이너가 없습니다."
    fi
    cd /home/ubuntu
fi

# 로그 디렉토리 생성
mkdir -p /home/ubuntu/logs/spring
mkdir -p /home/ubuntu/logs/postgresql
mkdir -p /home/ubuntu/logs/redis

# 새 컨테이너 시작
log_info "새로운 컨테이너들을 시작합니다..."
cd seurasaeng_be
docker-compose up -d
cd /home/ubuntu

# 데이터베이스 연결 대기
wait_for_database() {
    local max_attempts=60
    local attempt=1
    
    log_info "데이터베이스 서비스 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1; then
            if docker exec seuraseung-redis redis-cli -a redis123! ping >/dev/null 2>&1; then
                log_success "✅ 데이터베이스 연결 성공"
                return 0
            fi
        fi
        
        log_info "데이터베이스 준비 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_error "데이터베이스 연결 시간 초과"
    return 1
}

if ! wait_for_database; then
    log_error "데이터베이스 연결 실패"
    exit 1
fi

# Spring Boot 헬스체크
backend_health_check() {
    local max_attempts=60
    local attempt=1
    
    log_info "Spring Boot 애플리케이션 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps | grep seuraseung-backend | grep -q "Up"; then
            if curl -f -s --connect-timeout 5 --max-time 10 http://localhost:8080/actuator/health >/dev/null 2>&1; then
                log_success "✅ Spring Boot 헬스체크 통과"
                return 0
            fi
        fi
        
        log_info "Spring Boot 준비 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_error "Spring Boot 헬스체크 시간 초과"
    docker logs seuraseung-backend --tail=50
    return 1
}

if ! backend_health_check; then
    log_error "Spring Boot 서비스 시작 실패"
    
    # 롤백 시도
    log_warning "이전 버전으로 롤백을 시도합니다..."
    if [ -f "seurasaeng_be/docker-compose.yml.backup" ]; then
        cd seurasaeng_be
        docker-compose down --remove-orphans
        cp docker-compose.yml.backup docker-compose.yml
        docker-compose up -d
        cd /home/ubuntu
        sleep 60
        
        if curl -f -s http://localhost:8080/actuator/health >/dev/null 2>&1; then
            log_warning "이전 버전으로 롤백되었습니다."
        else
            log_error "롤백도 실패했습니다."
        fi
    fi
    exit 1
fi

# 데이터베이스 스키마 확인 및 초기화
log_info "데이터베이스 스키마를 확인합니다..."
if [ -f "/home/ubuntu/database/setup-db.sh" ]; then
    bash /home/ubuntu/database/setup-db.sh
fi

# 포트 상태 확인
log_info "포트 상태를 확인합니다..."
if netstat -tuln | grep -q ":8080 "; then
    log_success "✅ 포트 8080 정상 바인딩"
else
    log_error "❌ 포트 8080 바인딩 실패"
fi

# 최종 상태 확인
log_info "전체 서비스 상태:"
cd seurasaeng_be
docker-compose ps
cd /home/ubuntu

# 배포 완료
log_success "🎉 Spring Boot Backend 배포 완료!"
echo
log_info "=== 🌐 서비스 접근 정보 ==="
log_info "🔗 Backend API: http://10.0.2.166:8080"
log_info "🔍 헬스체크: http://10.0.2.166:8080/actuator/health"
log_info "🌐 프론트엔드 프록시: https://seurasaeng.site/api"
echo
log_info "=== 📊 관리 명령어 ==="
log_info "📊 상태 확인: cd seurasaeng_be && docker-compose ps"
log_info "📋 로그 확인: docker logs seuraseung-backend"

# 배포 정보 기록
{
    echo "$(date): Backend deployment completed"
    echo "  - Backend Health: $(curl -f -s http://localhost:8080/actuator/health >/dev/null 2>&1 && echo "HEALTHY" || echo "FAILED")"
    echo "  - PostgreSQL: $(docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1 && echo "CONNECTED" || echo "FAILED")"
    echo "  - Redis: $(docker exec seuraseung-redis redis-cli -a redis123! ping >/dev/null 2>&1 && echo "CONNECTED" || echo "FAILED")"
} >> /home/ubuntu/deployment.log

log_success "🔗 Backend 준비 완료! 프론트엔드와 연동 가능합니다!"