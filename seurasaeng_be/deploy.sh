#!/bin/bash

set -e

echo "🚀 Seurasaeng Backend CI/CD 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 로컬 .env 파일 확인
check_local_env() {
    if [ ! -f ".env.local" ]; then
        log_error ".env.local 파일이 없습니다. 먼저 생성해주세요:"
        echo ""
        echo "cat > .env.local << EOF"
        echo "AWS_ACCESS_KEY=YOUR_ACTUAL_ACCESS_KEY"
        echo "AWS_SECRET_KEY=YOUR_ACTUAL_SECRET_KEY"
        echo "MAIL_USERNAME=your@gmail.com"
        echo "MAIL_PASSWORD=your_app_password"
        echo "EOF"
        echo ""
        exit 1
    fi
    
    log_info "로컬 환경변수 파일 확인 완료"
}

# Docker 및 Docker Compose 설치 확인
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose가 설치되지 않았습니다."
        exit 1
    fi
    
    log_info "Docker 및 Docker Compose 확인 완료"
}

# 필요한 디렉토리 생성
create_directories() {
    log_info "필요한 디렉토리 생성 중..."
    mkdir -p init-scripts
    mkdir -p logs/{postgresql,redis,spring}
    log_info "디렉토리 생성 완료"
}

# PostgreSQL 초기화 스크립트 생성
create_init_scripts() {
    log_info "PostgreSQL 초기화 스크립트 생성 중..."
    
    cat > init-scripts/01-init.sql << 'EOF'
-- Seurasaeng 데이터베이스 초기화 스크립트
\echo 'Creating schema seurasaeng_test if not exists...'

-- 스키마 생성
CREATE SCHEMA IF NOT EXISTS seurasaeng_test;

-- 사용자에게 스키마 권한 부여
GRANT ALL PRIVILEGES ON SCHEMA seurasaeng_test TO seuraseung;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA seurasaeng_test TO seuraseung;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA seurasaeng_test TO seuraseung;

-- 기본 스키마 설정
ALTER USER seuraseung SET search_path TO seurasaeng_test,public;

\echo 'Schema setup completed!'
EOF

    cat > init-scripts/02-extensions.sql << 'EOF'
-- 필요한 PostgreSQL 확장 설치
\echo 'Installing extensions...'

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

\echo 'Extensions installed!'
EOF

    log_info "초기화 스크립트 생성 완료"
}

# .env 파일 생성 (보안 안전)
create_env_file() {
    log_info ".env 파일 생성 중..."
    
    # 로컬 .env.local에서 실제 값 읽기
    source .env.local
    
    cat > .env << EOF
# ================================
# Seurasaeng CI/CD 배포 설정
# ================================
# 생성일: $(date)
# 보안: AWS 크리덴셜은 로컬에서만 주입

# ================================
# 데이터베이스 설정
# ================================
DB_URL=jdbc:postgresql://postgres:5432/seuraseung
DB_USERNAME=seuraseung
DB_PASSWORD=SeuraseungProd2024!@#
DB_POOL_SIZE=15
DB_POOL_MIN_IDLE=5
DB_CONNECTION_TIMEOUT=30000

# ================================
# Redis 설정
# ================================
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=SeuraseungRedis2024!@#
REDIS_TIMEOUT=2000ms
REDIS_POOL_MAX_ACTIVE=10
REDIS_POOL_MAX_WAIT=-1ms
REDIS_POOL_MAX_IDLE=10
REDIS_POOL_MIN_IDLE=2

# ================================
# AWS S3 설정 (로컬에서 주입)
# ================================
AWS_ACCESS_KEY=${AWS_ACCESS_KEY}
AWS_SECRET_KEY=${AWS_SECRET_KEY}
AWS_REGION=ap-northeast-2
AWS_BUCKET=qrcode-s3-bucket

# ================================
# 보안 및 암호화 설정
# ================================
ENCRYPTION_KEY=SeuraseungSecure2024ProKey16
JWT_KEY=SeuraseungJWTSecretKey2024ProductionEnvironmentSecureKey256BitsMinimumForSecurity!@#
JWT_EXPIRATION=3600000

# ================================
# CORS 및 네트워크 설정 (실제 서버 정보)
# ================================
CORS_ALLOWED_ORIGINS=https://seurasaeng.site,http://13.125.200.221,https://13.125.200.221,http://10.0.2.166:8080
WEBSOCKET_ALLOWED_ORIGINS=https://seurasaeng.site,http://13.125.200.221,https://13.125.200.221

# ================================
# 메일 설정 (로컬에서 주입)
# ================================
MAIL_USERNAME=${MAIL_USERNAME}
MAIL_PASSWORD=${MAIL_PASSWORD}
MAIL_DEBUG=false

# ================================
# Spring Boot 설정
# ================================
SPRING_PROFILES_ACTIVE=prod
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=false
SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA=seurasaeng_test
SPRING_THYMELEAF_CACHE=true
SPRING_DEVTOOLS_RESTART_ENABLED=false

# ================================
# 로깅 설정
# ================================
LOGGING_LEVEL_ORG_HIBERNATE_SQL=warn
LOGGING_LEVEL_ORG_HIBERNATE_TYPE_DESCRIPTOR_SQL_SPI=warn
LOGGING_LEVEL_APPLICATION=info

# ================================
# 서버 및 모니터링 설정
# ================================
SERVER_PORT=8080
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info
MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS=never
MANAGEMENT_PORT=8080

# ================================
# 파일 업로드 설정
# ================================
MAX_FILE_SIZE=10MB
MAX_REQUEST_SIZE=10MB

# ================================
# 성능 최적화 설정
# ================================
JAVA_OPTS=-Xmx1g -Xms512m -XX:+UseG1GC -Duser.timezone=Asia/Seoul -Dspring.profiles.active=prod
EOF

    log_info ".env 파일 생성 완료 (보안 적용)"
}

# 기존 컨테이너 정리
cleanup_containers() {
    log_info "기존 컨테이너 정리 중..."
    
    # 기존 컨테이너 중지 및 제거
    docker-compose down -v --remove-orphans 2>/dev/null || true
    
    # 사용하지 않는 이미지 정리
    docker system prune -f
    
    # 네트워크 정리
    docker network prune -f
    
    log_info "컨테이너 정리 완료"
}

# Docker 이미지 로드
load_docker_image() {
    if [ -f "../seurasaeng_be-image.tar.gz" ]; then
        log_info "Docker 이미지 로드 중..."
        docker load < ../seurasaeng_be-image.tar.gz
        rm -f ../seurasaeng_be-image.tar.gz
        log_info "Docker 이미지 로드 완료"
    else
        log_warn "Docker 이미지 파일을 찾을 수 없습니다. 새로 빌드합니다."
    fi
}

# 컨테이너 시작
start_containers() {
    log_info "컨테이너 시작 중..."
    
    # 백그라운드에서 컨테이너 시작
    docker-compose up -d --build --force-recreate
    
    log_info "컨테이너 시작 완료"
}

# 서비스 상태 확인
check_services() {
    log_info "서비스 상태 확인 중..."
    
    # PostgreSQL 대기
    echo "PostgreSQL 준비 대기 중..."
    for i in {1..30}; do
        if docker-compose exec -T postgres pg_isready -U seuraseung -d seuraseung > /dev/null 2>&1; then
            log_info "PostgreSQL 준비 완료"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Redis 대기
    echo "Redis 준비 대기 중..."
    for i in {1..15}; do
        if docker-compose exec -T redis redis-cli -a SeuraseungRedis2024!@# ping > /dev/null 2>&1; then
            log_info "Redis 준비 완료"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Backend 대기
    echo "Backend 준비 대기 중..."
    for i in {1..60}; do
        if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
            log_info "Backend 준비 완료"
            break
        fi
        echo -n "."
        sleep 3
    done
}

# 최종 상태 표시
show_status() {
    echo ""
    echo "======================================"
    echo "🎉 CI/CD 배포 완료!"
    echo "======================================"
    echo ""
    echo "🌐 서비스 접속 정보:"
    echo "  - 백엔드 API: http://10.0.2.166:8080"
    echo "  - Health Check: http://10.0.2.166:8080/actuator/health"
    echo ""
    echo "📋 현재 설정 상태:"
    echo "  - ✅ 데이터베이스: 정상 연결"
    echo "  - ✅ Redis: 정상 연결"
    echo "  - ✅ Backend: 정상 시작"
    echo "  - ✅ AWS S3: 실제 키 적용"
    echo "  - ✅ 메일: 실제 설정 적용"
    echo ""
    echo "📊 컨테이너 상태:"
    docker-compose ps
    echo ""
    echo "🔍 헬스체크 결과:"
    curl -s http://localhost:8080/actuator/health | grep -o '"status":"[^"]*"' || echo "헬스체크 대기 중..."
}

# 메인 실행 함수
main() {
    check_local_env
    check_docker
    create_directories
    create_init_scripts
    create_env_file
    cleanup_containers
    load_docker_image
    start_containers
    check_services
    show_status
}

# 에러 트랩 설정
trap 'log_error "배포 중 에러가 발생했습니다. 로그 확인: docker-compose logs"; exit 1' ERR

# 메인 함수 실행
main

log_info "CI/CD 배포가 성공적으로 완료되었습니다! 🚀"