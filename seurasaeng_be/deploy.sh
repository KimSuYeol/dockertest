#!/bin/bash

set -e  # 에러 발생 시 스크립트 중단

echo "🚀 Seurasaeng Backend 프로덕션 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 서버 정보
FRONTEND_IP="13.125.200.221"
BACKEND_IP="10.0.2.166"
DOMAIN="https://seurasaeng.site"

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

# 보안 경고 표시
show_security_warning() {
    echo -e "${RED}🔒 보안 설정 필수 변경 사항${NC}"
    echo "=================================="
    echo -e "${YELLOW}다음 값들을 실제 프로덕션 값으로 변경하세요:${NC}"
    echo "1. AWS_ACCESS_KEY / AWS_SECRET_KEY"
    echo "2. MAIL_PASSWORD (Gmail 앱 패스워드)"
    echo "3. 데이터베이스 패스워드 확인"
    echo "4. Redis 패스워드 확인"
    echo ""
    read -p "계속 진행하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "배포를 취소했습니다."
        exit 1
    fi
}

# Docker 및 Docker Compose 설치 확인
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다."
        echo "설치 방법: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose가 설치되지 않았습니다."
        echo "설치 방법: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
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

# .env 파일 생성 (프로덕션 설정)
create_env_file() {
    log_info "프로덕션용 .env 파일 생성 중..."
    
    cat > .env << EOF
# ================================
# Seurasaeng 프로덕션 환경 설정
# ================================
# 생성일: $(date)
# 서버: 프론트엔드($FRONTEND_IP), 백엔드($BACKEND_IP)
# 도메인: $DOMAIN

# ================================
# 데이터베이스 설정 (프로덕션 강화)
# ================================
DB_URL=jdbc:postgresql://postgres:5432/seuraseung
DB_USERNAME=seuraseung
DB_PASSWORD=SeuraseungProd2024!@#
DB_POOL_SIZE=15
DB_POOL_MIN_IDLE=5
DB_CONNECTION_TIMEOUT=30000

# ================================
# Redis 설정 (프로덕션 강화)
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
# AWS S3 설정 (🚨 실제 키로 변경 필요)
# ================================
AWS_ACCESS_KEY=AKIA...여기에_실제_액세스키
AWS_SECRET_KEY=여기에_실제_시크릿키
AWS_REGION=ap-northeast-2
AWS_BUCKET=seurasaeng-profile-qrcode

# ================================
# 보안 및 암호화 설정 (프로덕션 강화)
# ================================
ENCRYPTION_KEY=SeuraseungSecure2024ProKey16
JWT_KEY=SeuraseungJWTSecretKey2024ProductionEnvironmentSecureKey256BitsMinimumForSecurity!@#
JWT_EXPIRATION=3600000

# ================================
# CORS 및 네트워크 설정 (실제 서버 정보)
# ================================
CORS_ALLOWED_ORIGINS=$DOMAIN,http://$FRONTEND_IP,https://$FRONTEND_IP,http://$BACKEND_IP:8080
WEBSOCKET_ALLOWED_ORIGINS=$DOMAIN,http://$FRONTEND_IP,https://$FRONTEND_IP

# ================================
# 메일 설정 (🚨 실제 Gmail 설정으로 변경 필요)
# ================================
MAIL_USERNAME=seurasaeng.official@gmail.com
MAIL_PASSWORD=여기에_실제_Gmail_앱패스워드
MAIL_DEBUG=false

# ================================
# Spring Boot 설정 (프로덕션 최적화)
# ================================
SPRING_PROFILES_ACTIVE=prod
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=false
SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA=seurasaeng_test
SPRING_THYMELEAF_CACHE=true
SPRING_DEVTOOLS_RESTART_ENABLED=false

# ================================
# 로깅 설정 (프로덕션)
# ================================
LOGGING_LEVEL_ORG_HIBERNATE_SQL=warn
LOGGING_LEVEL_ORG_HIBERNATE_TYPE_DESCRIPTOR_SQL_SPI=warn
LOGGING_LEVEL_APPLICATION=info

# ================================
# 서버 및 모니터링 설정 (보안 강화)
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

    log_info "프로덕션용 .env 파일 생성 완료"
    
    # 보안 경고 표시
    echo ""
    log_warn "🔒 보안 주의사항:"
    echo "1. AWS_ACCESS_KEY / AWS_SECRET_KEY를 실제 값으로 변경하세요"
    echo "2. MAIL_PASSWORD를 실제 Gmail 앱 패스워드로 변경하세요"
    echo "3. 데이터베이스/Redis 패스워드가 충분히 강력한지 확인하세요"
    echo ""
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
    log_info "프로덕션 컨테이너 시작 중..."
    
    # 백그라운드에서 컨테이너 시작 (강제 리빌드)
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
    echo "🎉 프로덕션 배포 완료!"
    echo "======================================"
    echo ""
    echo "🌐 서비스 접속 정보:"
    echo "  - 백엔드 API: http://$BACKEND_IP:8080"
    echo "  - 프론트엔드: http://$FRONTEND_IP"
    echo "  - 도메인: $DOMAIN"
    echo ""
    echo "🔍 상태 확인:"
    echo "  - Health Check: http://$BACKEND_IP:8080/actuator/health"
    echo "  - Info: http://$BACKEND_IP:8080/actuator/info"
    echo ""
    echo "🗄️ 데이터베이스 정보:"
    echo "  - PostgreSQL: $BACKEND_IP:5432"
    echo "  - Redis: $BACKEND_IP:6379"
    echo ""
    echo "📋 로그 확인 명령어:"
    echo "  - docker-compose logs -f backend"
    echo "  - docker-compose logs -f postgres"
    echo "  - docker-compose logs -f redis"
    echo ""
    echo "🔧 컨테이너 관리:"
    echo "  - 재시작: docker-compose restart"
    echo "  - 중지: docker-compose down"
    echo "  - 업데이트: docker-compose up -d --build"
    echo ""
    echo "🚨 필수 작업:"
    echo "  1. .env 파일에서 AWS 키 설정"
    echo "  2. .env 파일에서 Gmail 패스워드 설정"
    echo "  3. 보안 그룹에서 포트 8080 열기"
    echo ""
    echo "현재 컨테이너 상태:"
    docker-compose ps
}

# 메인 실행 함수
main() {
    show_security_warning
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
trap 'log_error "배포 중 에러가 발생했습니다. 로그를 확인해주세요: docker-compose logs"; exit 1' ERR

# 메인 함수 실행
main

log_info "Seurasaeng Backend 프로덕션 배포가 성공적으로 완료되었습니다! 🚀"