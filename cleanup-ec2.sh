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

log_info "🧹 EC2 Docker 환경 정리를 시작합니다..."

# 현재 상태 확인
log_info "현재 Docker 상태를 확인합니다..."
echo "=== 실행 중인 컨테이너 ==="
docker ps 2>/dev/null || log_warning "Docker가 실행되지 않았거나 권한이 없습니다."

echo -e "\n=== 모든 컨테이너 ==="
docker ps -a 2>/dev/null || true

echo -e "\n=== Docker 이미지 ==="
docker images 2>/dev/null || true

echo -e "\n=== Docker 볼륨 ==="
docker volume ls 2>/dev/null || true

echo -e "\n=== Docker 네트워크 ==="
docker network ls 2>/dev/null || true

echo -e "\n=== 디스크 사용량 (정리 전) ==="
df -h /

# 사용자 확인
echo -e "\n${YELLOW}⚠️  WARNING: 모든 Docker 리소스와 관련 파일들이 삭제됩니다!${NC}"
echo "다음 항목들이 삭제됩니다:"
echo "  - 모든 Docker 컨테이너"
echo "  - 모든 Docker 이미지"
echo "  - 모든 Docker 볼륨"
echo "  - 사용자 정의 네트워크"
echo "  - 프로젝트 파일들 (백업됨)"
echo "  - 로그 파일들 (백업됨)"
echo ""
read -p "정말로 계속 진행하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "작업이 취소되었습니다."
    exit 1
fi

# 1단계: 모든 컨테이너 중지
log_info "1단계: 모든 컨테이너를 중지합니다..."
RUNNING_CONTAINERS=$(docker ps -q 2>/dev/null)
if [ ! -z "$RUNNING_CONTAINERS" ]; then
    echo "중지할 컨테이너: $RUNNING_CONTAINERS"
    docker stop $RUNNING_CONTAINERS
    log_success "모든 실행 중인 컨테이너가 중지되었습니다."
else
    log_info "실행 중인 컨테이너가 없습니다."
fi

# 2단계: 모든 컨테이너 삭제
log_info "2단계: 모든 컨테이너를 삭제합니다..."
ALL_CONTAINERS=$(docker ps -aq 2>/dev/null)
if [ ! -z "$ALL_CONTAINERS" ]; then
    echo "삭제할 컨테이너: $ALL_CONTAINERS"
    docker rm $ALL_CONTAINERS
    log_success "모든 컨테이너가 삭제되었습니다."
else
    log_info "삭제할 컨테이너가 없습니다."
fi

# 3단계: 모든 이미지 삭제
log_info "3단계: 모든 Docker 이미지를 삭제합니다..."
ALL_IMAGES=$(docker images -q 2>/dev/null)
if [ ! -z "$ALL_IMAGES" ]; then
    echo "삭제할 이미지 개수: $(echo $ALL_IMAGES | wc -w)"
    docker rmi $ALL_IMAGES -f
    log_success "모든 이미지가 삭제되었습니다."
else
    log_info "삭제할 이미지가 없습니다."
fi

# 4단계: 모든 볼륨 삭제
log_info "4단계: 모든 Docker 볼륨을 삭제합니다..."
ALL_VOLUMES=$(docker volume ls -q 2>/dev/null)
if [ ! -z "$ALL_VOLUMES" ]; then
    echo "삭제할 볼륨: $ALL_VOLUMES"
    docker volume rm $ALL_VOLUMES -f
    log_success "모든 볼륨이 삭제되었습니다."
else
    log_info "삭제할 볼륨이 없습니다."
fi

# 5단계: 사용자 정의 네트워크 삭제
log_info "5단계: 사용자 정의 네트워크를 삭제합니다..."
CUSTOM_NETWORKS=$(docker network ls --filter type=custom --format "{{.Name}}" 2>/dev/null | grep -v "bridge\|host\|none")
if [ ! -z "$CUSTOM_NETWORKS" ]; then
    echo "삭제할 네트워크: $CUSTOM_NETWORKS"
    echo "$CUSTOM_NETWORKS" | xargs docker network rm 2>/dev/null || true
    log_success "사용자 정의 네트워크가 삭제되었습니다."
else
    log_info "삭제할 사용자 정의 네트워크가 없습니다."
fi

# 6단계: Docker 시스템 정리
log_info "6단계: Docker 시스템 전체 정리를 수행합니다..."
docker system prune -a -f --volumes 2>/dev/null || true
log_success "Docker 시스템 정리가 완료되었습니다."

# 7단계: 관련 파일들 정리
log_info "7단계: 관련 파일들을 정리합니다..."

# 백업 디렉토리 생성
BACKUP_DIR="/home/ubuntu/backup.$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p $BACKUP_DIR

# 기존 프로젝트 파일들 정리 (백업 후 삭제)
if [ -d "/home/ubuntu/seurasaeng_be" ]; then
    log_info "백엔드 프로젝트 파일을 백업 후 삭제합니다..."
    sudo mv /home/ubuntu/seurasaeng_be $BACKUP_DIR/
    log_success "백엔드 파일들이 $BACKUP_DIR/seurasaeng_be로 백업되었습니다."
fi

if [ -d "/home/ubuntu/seurasaeng_fe" ]; then
    log_info "기존 프론트엔드 프로젝트 파일을 백업 후 삭제합니다..."
    sudo mv /home/ubuntu/seurasaeng_fe $BACKUP_DIR/
    log_success "프론트엔드 파일들이 $BACKUP_DIR/seurasaeng_fe로 백업되었습니다."
fi

if [ -d "/home/ubuntu/database" ]; then
    log_info "데이터베이스 설정 파일을 백업 후 삭제합니다..."
    sudo mv /home/ubuntu/database $BACKUP_DIR/
    log_success "데이터베이스 파일들이 $BACKUP_DIR/database로 백업되었습니다."
fi

if [ -d "/home/ubuntu/scripts" ]; then
    log_info "스크립트 파일들을 백업 후 삭제합니다..."
    sudo mv /home/ubuntu/scripts $BACKUP_DIR/
    log_success "스크립트 파일들이 $BACKUP_DIR/scripts로 백업되었습니다."
fi

# Docker Compose 파일들 정리
if [ -f "/home/ubuntu/docker-compose.yml" ]; then
    sudo mv /home/ubuntu/docker-compose.yml $BACKUP_DIR/
fi

# 로그 디렉토리 정리 (백업 후 삭제)
if [ -d "/home/ubuntu/logs" ]; then
    log_info "로그 디렉토리를 백업 후 정리합니다..."
    sudo mv /home/ubuntu/logs $BACKUP_DIR/
    log_success "로그 파일들이 $BACKUP_DIR/logs로 백업되었습니다."
fi

# 임시 파일들 정리
sudo rm -f /home/ubuntu/*.tar.gz
sudo rm -f /home/ubuntu/*.log
sudo rm -f /home/ubuntu/deploy*.sh

# 이전 백업들도 정리 (30일 이상된 것들)
find /home/ubuntu -maxdepth 1 -name "*.backup.*" -mtime +30 -exec sudo rm -rf {} \; 2>/dev/null || true

log_success "파일 정리가 완료되었습니다."

# 8단계: 시스템 정리
log_info "8단계: 시스템 캐시를 정리합니다..."

# APT 캐시 정리
sudo apt autoremove -y 2>/dev/null || true
sudo apt autoclean 2>/dev/null || true

# 임시 파일 정리
sudo rm -rf /tmp/* 2>/dev/null || true

# 로그 로테이션
sudo logrotate -f /etc/logrotate.conf 2>/dev/null || true

log_success "시스템 정리가 완료되었습니다."

# 9단계: 포트 확인
log_info "9단계: 사용 중인 포트를 확인합니다..."
echo "=== 현재 사용 중인 주요 포트 ==="
sudo netstat -tulpn | grep -E ":80 |:443 |:8080 |:5432 |:6379 " 2>/dev/null || log_info "Docker 관련 포트가 모두 해제되었습니다."

# 10단계: 최종 확인
log_info "10단계: 정리 후 상태를 확인합니다..."
echo "=== 정리 후 Docker 상태 ==="
echo "컨테이너: $(docker ps -a 2>/dev/null | wc -l) 개 (헤더 포함)"
echo "이미지: $(docker images 2>/dev/null | wc -l) 개 (헤더 포함)"
echo "볼륨: $(docker volume ls 2>/dev/null | wc -l) 개 (헤더 포함)"
echo "네트워크: $(docker network ls 2>/dev/null | wc -l) 개 (헤더 포함)"

# 디스크 사용량 확인
echo -e "\n=== 디스크 사용량 (정리 후) ==="
df -h /

# 메모리 사용량 확인
echo -e "\n=== 메모리 사용량 ==="
free -h

# 11단계: 새로운 환경 준비
log_info "11단계: 새로운 환경을 준비합니다..."

# 필요한 디렉토리 생성
sudo mkdir -p /home/ubuntu/logs/nginx
sudo chown -R ubuntu:ubuntu /home/ubuntu/logs

# Docker 서비스 상태 확인
if systemctl is-active --quiet docker; then
    log_success "Docker 서비스가 정상 실행 중입니다."
else
    log_warning "Docker 서비스를 시작합니다..."
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Docker 권한 확인
if groups $USER | grep -q docker; then
    log_success "Docker 권한이 설정되어 있습니다."
else
    log_warning "Docker 권한을 설정합니다..."
    sudo usermod -aG docker $USER
    log_info "로그아웃 후 다시 로그인하여 Docker 권한을 적용해주세요."
fi

log_success "🎉 EC2 Docker 환경 정리가 완료되었습니다!"
echo ""
log_info "📋 정리된 항목:"
log_info "  ✅ 모든 Docker 컨테이너"
log_info "  ✅ 모든 Docker 이미지"
log_info "  ✅ 모든 Docker 볼륨"
log_info "  ✅ 사용자 정의 네트워크"
log_info "  ✅ 프로젝트 파일들 (백업됨)"
log_info "  ✅ 로그 파일들 (백업됨)"
log_info "  ✅ 시스템 캐시"
echo ""
log_info "🔄 이제 새로운 프론트엔드 프로젝트를 배포할 수 있습니다!"
echo ""
log_info "📁 백업된 파일들 위치:"
log_info "  📦 $BACKUP_DIR"
ls -la $BACKUP_DIR 2>/dev/null || log_info "  (백업된 파일이 없습니다)"
echo ""
log_info "🚀 다음 단계:"
log_info "  1. 새로운 프로젝트 파일을 업로드"
log_info "  2. docker-compose up --build 실행"
log_info "  3. 서비스 접속 확인"
echo ""
log_success "정리 작업이 성공적으로 완료되었습니다! 🎊"