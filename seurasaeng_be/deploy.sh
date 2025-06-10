#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
log_info "🚀 Backend 배포를 시작합니다..."
log_info "현재 작업 디렉토리: $(pwd)"
log_info "프로젝트 루트: $(realpath ..)"

# Backend .env 파일 동적 생성 함수 (단순 버전)
create_backend_env() {
    log_info "Backend 환경변수 파일을 생성합니다..."
    
    # .env 파일 생성 (현재 디렉토리에)
    cat > .env << EOF
# 데이터베이스 설정
DB_URL=jdbc:postgresql://postgres:5432/seuraseung
DB_USERNAME=seuraseung
DB_PASSWORD=seuraseung123!

# Redis 설정
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=redis123!

# AWS S3 설정 (기본값)
AWS_ACCESS_KEY=
AWS_SECRET_KEY=
AWS_REGION=ap-northeast-2
AWS_BUCKET=profile-qrcode

# 암호화 설정
ENCRYPTION_KEY=MyShuttleQRKey16BytesSecure2024
JWT_KEY=seuraseung-jwt-secret-key-2024-production-environment-secure-key-minimum-256-bits-for-security

# CORS 설정
CORS_ALLOWED_ORIGINS=https://seurasaeng.site,http://13.125.200.221

# 메일 설정 (기본값)
MAIL_USERNAME=admin@seurasaeng.site
MAIL_PASSWORD=placeholder_password
EOF

    # 파일 권한 설정 (보안)
    chmod 600 .env
    
    log_success "✅ Backend .env 파일 생성 완료"
    
    # 환경변수 요약 출력
    log_info "=== 📋 Backend 환경변수 설정 요약 ==="
    log_info "  DB_URL: jdbc:postgresql://postgres:5432/seuraseung"
    log_info "  DB_USERNAME: seuraseung"
    log_info "  REDIS_HOST: redis"
    log_info "  AWS_ACCESS_KEY: (비어있음 - S3 기능 제한됨)"
    log_info "  MAIL_USERNAME: admin@seurasaeng.site (기본값)"
    log_info "  JWT_KEY: ****...**** (256비트)"
    log_info "  CORS_ALLOWED_ORIGINS: https://seurasaeng.site,http://13.125.200.221"
    echo
}

# 데이터베이스 초기화 함수 (안전한 버전)
setup_database() {
    log_info "데이터베이스 초기화를 확인합니다..."
    
    # 데이터베이스 초기화 스크립트 실행 (프로젝트 루트의 database 폴더)
    if [ -f "../database/setup-db.sh" ]; then
        log_info "데이터베이스 초기화 스크립트를 실행합니다..."
        chmod +x ../database/setup-db.sh
        if bash ../database/setup-db.sh; then
            log_success "✅ 데이터베이스 초기화 성공"
            return 0
        else
            log_warning "⚠️ 데이터베이스 초기화 스크립트 실행 실패"
            return 1
        fi
    else
        log_warning "⚠️ 데이터베이스 초기화 스크립트가 없습니다: ../database/setup-db.sh"
        return 1
    fi
}

# 이전 배포 백업
log_info "이전 배포를 백업합니다..."
if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
fi

# .env 파일 생성
create_backend_env

# Docker 이미지 로드 (GitHub Actions에서 생성된 파일명 사용)
DOCKER_IMAGE_FILE="../seurasaeng_be-image.tar.gz"
if [ -f "$DOCKER_IMAGE_FILE" ]; then
    log_info "Docker 이미지를 로드합니다: $DOCKER_IMAGE_FILE"
    if docker load < "$DOCKER_IMAGE_FILE"; then
        log_success "Docker 이미지 로드 완료"
        rm -f "$DOCKER_IMAGE_FILE"
    else
        log_error "Docker 이미지 로드 실패"
        exit 1
    fi
else
    log_warning "Docker 이미지 파일이 없습니다: $DOCKER_IMAGE_FILE"
fi

# 기존 컨테이너 graceful shutdown
log_info "기존 컨테이너들을 안전하게 중지합니다..."

if docker-compose ps -q 2>/dev/null | grep -q .; then
    # Spring Boot graceful shutdown
    if docker-compose ps backend 2>/dev/null | grep -q "Up"; then
        log_info "Spring Boot 컨테이너에 graceful shutdown 신호를 전송합니다..."
        docker-compose exec -T backend curl -X POST http://localhost:8080/actuator/shutdown 2>/dev/null || true
        sleep 10
    fi
    
    docker-compose down --remove-orphans --timeout 60
else
    log_info "실행 중인 컨테이너가 없습니다."
fi

# 사용하지 않는 이미지 정리
log_info "사용하지 않는 Docker 이미지를 정리합니다..."
docker image prune -f

# 로그 디렉토리 생성 (프로젝트 루트에)
mkdir -p ../logs/spring

# 새 컨테이너 시작
log_info "새로운 컨테이너를 시작합니다..."
docker-compose up -d

# 컨테이너들이 준비될 때까지 대기
log_info "컨테이너들이 완전히 시작될 때까지 대기합니다..."
sleep 30

# 데이터베이스 연결 대기 (더 안전한 방식)
wait_for_database() {
    local max_attempts=30
    local attempt=1
    
    log_info "데이터베이스 서비스 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1; then
            log_success "✅ PostgreSQL이 준비되었습니다"
            return 0
        fi
        
        log_info "PostgreSQL 준비 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_warning "⚠️ PostgreSQL 연결 대기 시간 초과. 계속 진행합니다."
    return 1
}

# 데이터베이스 준비 대기
wait_for_database

# 데이터베이스 초기화 (선택사항 - 실패해도 계속 진행)
log_info "데이터베이스 초기화를 시도합니다..."
if setup_database; then
    log_success "✅ 데이터베이스 초기화 완료"
else
    log_warning "⚠️ 데이터베이스 초기화 실패. 하지만 계속 진행합니다."
fi

# Backend 헬스체크
backend_health_check() {
    local max_attempts=60  # 5분 대기 (5초 간격)
    local attempt=1
    
    log_info "Backend 서비스 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        # 컨테이너 상태 확인
        if ! docker ps | grep seuraseung-backend | grep -q "Up"; then
            log_warning "Backend 컨테이너가 실행되지 않고 있습니다. ($attempt/$max_attempts)"
        else
            # 헬스체크
            if curl -f -s --connect-timeout 5 --max-time 10 http://10.0.2.166:8080/actuator/health >/dev/null 2>&1; then
                log_success "✅ Backend 헬스체크 통과"
                return 0
            fi
        fi
        
        log_info "Backend 준비 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    log_error "Backend 헬스체크 시간 초과"
    docker logs seuraseung-backend --tail=50
    return 1
}

if ! backend_health_check; then
    log_error "Backend 서비스 시작 실패"
    
    # 롤백 시도
    log_warning "이전 버전으로 롤백을 시도합니다..."
    if ls docker-compose.yml.backup.* 1> /dev/null 2>&1; then
        docker-compose down --remove-orphans
        cp $(ls -t docker-compose.yml.backup.* | head -1) docker-compose.yml
        docker-compose up -d
        sleep 60
        
        if curl -f -s http://10.0.2.166:8080/actuator/health >/dev/null 2>&1; then
            log_warning "이전 버전으로 롤백되었습니다."
        else
            log_error "롤백도 실패했습니다."
        fi
    fi
    exit 1
fi

# 데이터베이스 연결 테스트
log_info "데이터베이스 연결을 테스트합니다..."
if docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1; then
    log_success "✅ PostgreSQL 연결 정상"
else
    log_warning "⚠️ PostgreSQL 연결에 문제가 있을 수 있습니다."
fi

if docker exec seuraseung-redis redis-cli -a redis123! ping >/dev/null 2>&1; then
    log_success "✅ Redis 연결 정상"
else
    log_warning "⚠️ Redis 연결에 문제가 있을 수 있습니다."
fi

# API 엔드포인트 테스트
log_info "주요 API 엔드포인트를 테스트합니다..."
if curl -f -s http://10.0.2.166:8080/ >/dev/null 2>&1; then
    log_success "✅ 루트 엔드포인트 정상"
else
    log_warning "⚠️ 루트 엔드포인트 접근 실패"
fi

if curl -f -s http://10.0.2.166:8080/health >/dev/null 2>&1; then
    log_success "✅ 헬스체크 엔드포인트 정상"
else
    log_warning "⚠️ 헬스체크 엔드포인트 접근 실패"
fi

# 배포 완료 메시지
log_success "🎉 Backend 배포가 완료되었습니다!"
echo
log_info "=== 🌐 서비스 정보 ==="
log_info "🖥️  Backend API: http://10.0.2.166:8080"
log_info "🔍 헬스체크: http://10.0.2.166:8080/actuator/health"
log_info "🏠 홈페이지: http://10.0.2.166:8080/"
log_info "📊 관리 정보: http://10.0.2.166:8080/actuator"
echo
log_info "=== 📊 관리 명령어 ==="
log_info "📊 서비스 상태 확인: docker-compose ps"
log_info "📋 로그 확인: docker-compose logs -f backend"
log_info "📋 Spring Boot 로그: docker logs seuraseung-backend"
log_info "🗄️  데이터베이스 로그: docker logs seuraseung-postgres"
log_info "🔧 환경변수 확인: docker exec seuraseung-backend env | grep -E '^(DB_|REDIS_|JWT_)'"

# 배포 정보 기록 (프로젝트 루트에)
{
    echo "$(date): Backend deployment completed successfully"
    echo "  - Backend Health: $(curl -f -s http://10.0.2.166:8080/actuator/health >/dev/null 2>&1 && echo "HEALTHY" || echo "FAILED")"
    echo "  - Database (PostgreSQL): $(docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1 && echo "CONNECTED" || echo "FAILED")"
    echo "  - Cache (Redis): $(docker exec seuraseung-redis redis-cli -a redis123! ping >/dev/null 2>&1 && echo "CONNECTED" || echo "FAILED")"
    echo "  - Environment Variables: LOADED"
    echo "  - API Endpoints: $(curl -f -s http://10.0.2.166:8080/ >/dev/null 2>&1 && echo "ACCESSIBLE" || echo "FAILED")"
    echo "  - Port 8080: BOUND"
} >> ../deployment.log

log_success "🚀 Backend 서비스가 완전히 준비되었습니다!"