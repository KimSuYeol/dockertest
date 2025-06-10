#!/bin/bash

set -e  # 에러 발생 시 스크립트 중단

echo "🚀 Backend 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
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
-- 데이터베이스 초기화 스크립트
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

# .env 파일 생성
create_env_file() {
    log_info ".env 파일 생성 중..."
    
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

# AWS S3 설정 (필요시 실제 값으로 변경)
AWS_ACCESS_KEY=
AWS_SECRET_KEY=
AWS_REGION=ap-northeast-2
AWS_BUCKET=profile-qrcode

# 보안 키
ENCRYPTION_KEY=MyShuttleQRKey16BytesSecure2024
JWT_KEY=seuraseung-jwt-secret-key-2024-production-environment-secure-key-minimum-256-bits-for-security

# CORS 설정
CORS_ALLOWED_ORIGINS=https://seurasaeng.site,http://13.125.200.221,https://13.125.200.221

# 메일 설정 (실제 사용시 변경 필요)
MAIL_USERNAME=youjiyeon4@gmail.com
MAIL_PASSWORD=hmqv wsha xdgs hdie

# Spring 설정
SPRING_JPA_HIBERNATE_DDL_AUTO=create-drop
SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA=seurasaeng_test
SPRING_PROFILES_ACTIVE=prod

# 로깅 설정
LOGGING_LEVEL_ORG_HIBERNATE_SQL=warn
LOGGING_LEVEL_ORG_HIBERNATE_TYPE_DESCRIPTOR_SQL_SPI=warn
LOGGING_LEVEL_APPLICATION=info
EOF

    log_info ".env 파일 생성 완료"
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
        log_warn "Docker 이미지 파일을 찾을 수 없습니다. 빌드를 진행합니다."
    fi
}

# 컨테이너 시작
start_containers() {
    log_info "컨테이너 시작 중..."
    
    # 백그라운드에서 컨테이너 시작
    docker-compose up -d --build
    
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
        if docker-compose exec -T redis redis-cli -a redis123! ping > /dev/null 2>&1; then
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
    echo "🎉 배포 완료!"
    echo "======================================"
    echo ""
    echo "서비스 URL:"
    echo "  - Backend: http://localhost:8080"
    echo "  - Health Check: http://localhost:8080/actuator/health"
    echo ""
    echo "데이터베이스 정보:"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo ""
    echo "로그 확인:"
    echo "  docker-compose logs -f backend"
    echo "  docker-compose logs -f postgres"
    echo "  docker-compose logs -f redis"
    echo ""
    echo "컨테이너 상태:"
    docker-compose ps
}

# 메인 실행 함수
main() {
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
trap 'log_error "배포 중 에러가 발생했습니다. 로그를 확인해주세요."; exit 1' ERR

# 메인 함수 실행
main

log_info "Backend 배포가 성공적으로 완료되었습니다!"