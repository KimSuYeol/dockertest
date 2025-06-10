#!/bin/bash

set -e

echo "🚀 Seurasaeng Backend 배포 시작..."

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# .env 파일 확인 (GitHub Actions에서 생성해서 전송됨)
if [ ! -f ".env" ]; then
    log_error ".env 파일이 없습니다. GitHub Actions에서 생성되어야 합니다."
    exit 1
fi

log_info ".env 파일 확인 완료 (GitHub Actions에서 생성됨)"

# 필요한 디렉토리 생성
mkdir -p init-scripts
mkdir -p logs

# PostgreSQL 초기화 스크립트 생성
cat > init-scripts/01-init.sql << 'EOF'
-- PostgreSQL 초기화 스크립트 (팀원 요청 기반)
\echo 'Creating schemas seurasaeng_test and seurasaeng_prod...'

-- 스키마 생성
CREATE SCHEMA IF NOT EXISTS seurasaeng_test;
CREATE SCHEMA IF NOT EXISTS seurasaeng_prod;

-- 사용자에게 스키마 권한 부여
GRANT ALL PRIVILEGES ON SCHEMA seurasaeng_test TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA seurasaeng_prod TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA seurasaeng_test TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA seurasaeng_prod TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA seurasaeng_test TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA seurasaeng_prod TO postgres;

-- 미래에 생성될 테이블들에 대한 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA seurasaeng_test GRANT ALL PRIVILEGES ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA seurasaeng_prod GRANT ALL PRIVILEGES ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA seurasaeng_test GRANT ALL PRIVILEGES ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA seurasaeng_prod GRANT ALL PRIVILEGES ON SEQUENCES TO postgres;

-- 기본 스키마 설정 (test를 기본으로)
ALTER USER postgres SET search_path TO seurasaeng_test,seurasaeng_prod,public;

-- 필요한 확장 설치
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\echo 'Schema setup completed!'
EOF

log_info "초기화 스크립트 생성 완료"

# 기존 컨테이너 정리
log_info "기존 컨테이너 정리 중..."
docker-compose down -v --remove-orphans 2>/dev/null || true
docker system prune -f

# Docker 이미지 로드 (있는 경우)
if [ -f "../seurasaeng_be-image.tar.gz" ]; then
    log_info "Docker 이미지 로드 중..."
    docker load < ../seurasaeng_be-image.tar.gz
    rm -f ../seurasaeng_be-image.tar.gz
fi

# 컨테이너 시작
log_info "컨테이너 시작 중..."
docker-compose up -d --build

# 서비스 상태 확인
log_info "서비스 상태 확인 중..."

# PostgreSQL 대기
echo "PostgreSQL 준비 대기 중..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U postgres -d postgres > /dev/null 2>&1; then
        log_info "PostgreSQL 준비 완료"
        break
    fi
    echo -n "."
    sleep 2
done

# Redis 대기
echo "Redis 준비 대기 중..."
for i in {1..15}; do
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
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

# 최종 상태 표시
echo ""
echo "======================================"
echo "🎉 배포 완료!"
echo "======================================"
echo ""
echo "🌐 서비스 접속 정보:"
echo "  - 백엔드 API: http://localhost:8080"
echo "  - Health Check: http://localhost:8080/actuator/health"
echo "  - Swagger UI: http://localhost:8080/swagger-ui.html"
echo ""
echo "📊 데이터베이스 정보:"
echo "  - 데이터베이스: postgres"
echo "  - 스키마: seurasaeng_test, seurasaeng_prod"
echo "  - 현재 사용: $(grep DB_SCHEMA .env | cut -d'=' -f2 2>/dev/null || echo 'seurasaeng_prod')"
echo ""
echo "📊 컨테이너 상태:"
docker-compose ps

log_info "배포가 성공적으로 완료되었습니다! 🚀"