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

# 환경변수 설정 (prod 환경)
export SPRING_PROFILES_ACTIVE=prod
export DB_SCHEMA=seurasaeng-prod
export REDIS_DATABASE=0

# 이전 배포 백업 (롤백 대비)
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
    log_warning "seurasaeng_be-image.tar.gz 파일이 없습니다. 기존 이미지를 사용합니다."
fi

# 기존 컨테이너 graceful shutdown
log_info "기존 컨테이너들을 안전하게 중지합니다..."
if [ -f "seurasaeng_be/docker-compose.yml" ]; then
    cd seurasaeng_be
    if docker-compose ps -q 2>/dev/null | grep -q .; then
        # Spring Boot graceful shutdown
        if docker-compose ps backend 2>/dev/null | grep -q "Up"; then
            log_info "Spring Boot 애플리케이션에 graceful shutdown 신호를 전송합니다..."
            docker-compose exec -T backend curl -X POST http://localhost:8080/actuator/shutdown 2>/dev/null || true
            sleep 10
        fi
        
        docker-compose down --remove-orphans --timeout 60
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
mkdir -p /home/ubuntu/logs/spring
mkdir -p /home/ubuntu/logs/postgresql
mkdir -p /home/ubuntu/logs/redis

# 환경변수 파일 생성 (prod 환경)
log_info "프로덕션 환경변수를 설정합니다..."
cat > seurasaeng_be/.env << EOF
# Spring 프로파일
SPRING_PROFILES_ACTIVE=prod

# 데이터베이스 설정
DB_URL=jdbc:postgresql://postgres:5432/seuraseung?currentSchema=seurasaeng-prod
DB_USERNAME=seuraseung
DB_PASSWORD=seuraseung123!

# Redis 설정
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0

# JWT 설정
JWT_KEY=seuraseung-jwt-secret-key-2024-prod-version-very-long-secret

# 암호화 키
ENCRYPTION_KEY=seuraseung-encryption-key-2024

# CORS 설정
CORS_ALLOWED_ORIGINS=https://seurasaeng.site,http://13.125.200.221

# AWS S3 설정 (실제 값은 GitHub Secrets에서 주입)
AWS_ACCESS_KEY=dummy
AWS_SECRET_KEY=dummy
AWS_REGION=ap-northeast-2
AWS_BUCKET=seuraseung-bucket

# 메일 설정
MAIL_USERNAME=dummy@gmail.com
MAIL_PASSWORD=dummy
EOF

# 새 컨테이너 시작
log_info "새로운 컨테이너들을 시작합니다..."
cd seurasaeng_be
docker-compose up -d
cd /home/ubuntu

# 데이터베이스 연결 대기 및 초기화
wait_for_database() {
    local max_attempts=60  # 5분 대기
    local attempt=1
    
    log_info "데이터베이스 서비스 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        # PostgreSQL 연결 확인
        if docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1; then
            log_success "✅ PostgreSQL 연결 성공"
            
            # Redis 연결 확인
            if docker exec seuraseung-redis redis-cli -a redis123! ping >/dev/null 2>&1; then
                log_success "✅ Redis 연결 성공"
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

# Spring Boot 애플리케이션 헬스체크
backend_health_check() {
    local max_attempts=60  # 5분 대기
    local attempt=1
    
    log_info "Spring Boot 애플리케이션 준비 대기 중..."
    
    while [ $attempt -le $max_attempts ]; do
        # 컨테이너 상태 확인
        if ! docker ps | grep seuraseung-backend | grep -q "Up"; then
            log_warning "Spring Boot 컨테이너가 실행되지 않고 있습니다. ($attempt/$max_attempts)"
        else
            # 헬스체크
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

# 데이터베이스 스키마 확인
log_info "데이터베이스 스키마를 확인합니다..."
PROD_SCHEMA_EXISTS=$(docker exec seuraseung-postgres psql -U seuraseung -d seuraseung -t -c "SELECT 1 FROM information_schema.schemata WHERE schema_name = 'seurasaeng-prod';" 2>/dev/null | xargs)

if [ "$PROD_SCHEMA_EXISTS" = "1" ]; then
    log_success "✅ seurasaeng-prod 스키마 존재 확인"
else
    log_warning "⚠️ seurasaeng-prod 스키마가 없습니다. 초기화 스크립트를 실행합니다."
    if [ -f "/home/ubuntu/database/setup-db.sh" ]; then
        bash /home/ubuntu/database/setup-db.sh
    fi
fi

# API 엔드포인트 테스트
log_info "API 엔드포인트를 테스트합니다..."

# 기본 헬스체크
if curl -f -s --connect-timeout 5 --max-time 10 http://localhost:8080/actuator/health >/dev/null 2>&1; then
    log_success "✅ 헬스체크 API 정상"
else
    log_warning "⚠️ 헬스체크 API 응답 없음"
fi

# 루트 엔드포인트 테스트
if curl -f -s --connect-timeout 5 --max-time 10 http://localhost:8080/ >/dev/null 2>&1; then
    log_success "✅ 루트 엔드포인트 정상"
else
    log_warning "⚠️ 루트 엔드포인트 응답 없음"
fi

# 데이터베이스 연결 상태 재확인
log_info "최종 데이터베이스 연결을 확인합니다..."
if docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1; then
    log_success "✅ PostgreSQL 최종 연결 확인"
else
    log_error "❌ PostgreSQL 연결 실패"
fi

if docker exec seuraseung-redis redis-cli -a redis123! ping >/dev/null 2>&1; then
    log_success "✅ Redis 최종 연결 확인"
else
    log_error "❌ Redis 연결 실패"
fi

# 포트 상태 확인
log_info "포트 상태를 확인합니다..."
if netstat -tuln | grep -q ":8080 "; then
    log_success "✅ 포트 8080이 정상적으로 바인딩되었습니다."
else
    log_error "❌ 포트 8080 바인딩에 실패했습니다."
fi

if netstat -tuln | grep -q ":5432 "; then
    log_success "✅ 포트 5432 (PostgreSQL)이 정상적으로 바인딩되었습니다."
else
    log_warning "⚠️ 포트 5432 바인딩 확인 필요"
fi

if netstat -tuln | grep -q ":6379 "; then
    log_success "✅ 포트 6379 (Redis)가 정상적으로 바인딩되었습니다."
else
    log_warning "⚠️ 포트 6379 바인딩 확인 필요"
fi

# 최종 상태 확인
log_info "전체 서비스 상태를 확인합니다..."
cd seurasaeng_be
docker-compose ps
cd /home/ubuntu

# 성능 및 리소스 사용량 확인
log_info "컨테이너 리소스 사용량:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker ps -q) || true

# 배포 완료 메시지
log_success "🎉 Spring Boot Backend 배포가 완료되었습니다!"
echo
log_info "=== 🌐 서비스 접근 정보 ==="
log_info "🔗 Backend API: http://10.0.2.166:8080"
log_info "🔍 헬스체크: http://10.0.2.166:8080/actuator/health"
log_info "🌐 프론트엔드 프록시: https://seurasaeng.site/api"
log_info "🗄️ PostgreSQL: localhost:5432 (seurasaeng-prod 스키마)"
log_info "📊 Redis: localhost:6379 (database 0)"
echo
log_info "=== 📊 관리 명령어 ==="
log_info "📊 서비스 상태 확인: cd seurasaeng_be && docker-compose ps"
log_info "📋 로그 확인: cd seurasaeng_be && docker-compose logs -f"
log_info "📋 Backend 로그: docker logs seuraseung-backend"
log_info "📋 DB 로그: docker logs seuraseung-postgres"
log_info "📋 Redis 로그: docker logs seuraseung-redis"
log_info "🗄️ DB 접속: docker exec -it seuraseung-postgres psql -U seuraseung -d seuraseung"
log_info "📊 Redis 접속: docker exec -it seuraseung-redis redis-cli -a redis123!"

# 배포 정보 기록
{
    echo "$(date): Spring Boot Backend deployment completed successfully"
    echo "  - Backend Health: $(curl -f -s http://localhost:8080/actuator/health >/dev/null 2>&1 && echo "HEALTHY" || echo "FAILED")"
    echo "  - PostgreSQL: $(docker exec seuraseung-postgres pg_isready -U seuraseung -d seuraseung >/dev/null 2>&1 && echo "CONNECTED" || echo "FAILED")"
    echo "  - Redis: $(docker exec seuraseung-redis redis-cli -a redis123! ping >/dev/null 2>&1 && echo "CONNECTED" || echo "FAILED")"
    echo "  - Port 8080: $(netstat -tuln | grep -q ":8080 " && echo "BOUND" || echo "FAILED")"
    echo "  - Schema: seurasaeng-prod"
    echo "  - Profile: prod"
} >> /home/ubuntu/deployment.log

# 성공적인 배포 백업 업데이트
if [ -f "seurasaeng_be/docker-compose.yml" ]; then
    cp seurasaeng_be/docker-compose.yml seurasaeng_be/docker-compose.yml.success
fi

# 시스템 리소스 최종 확인
log_info "=== 💾 시스템 리소스 사용량 ==="
df -h | grep -E "/$|/home"
free -h

log_success "🔗 Backend가 완전히 준비되었습니다. 프론트엔드와 연동이 가능합니다!"