#!/bin/bash

echo "🚀 Backend 배포 시작..."

# .env 파일 생성 (첫 배포시 테이블 자동 생성 설정)
cat > .env << EOF
DB_URL=jdbc:postgresql://postgres:5432/seuraseung
DB_USERNAME=seuraseung
DB_PASSWORD=seuraseung123!
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=redis123!
AWS_ACCESS_KEY=
AWS_SECRET_KEY=
AWS_REGION=ap-northeast-2
AWS_BUCKET=profile-qrcode
ENCRYPTION_KEY=MyShuttleQRKey16BytesSecure2024
JWT_KEY=seuraseung-jwt-secret-key-2024-production-environment-secure-key-minimum-256-bits-for-security
CORS_ALLOWED_ORIGINS=https://seurasaeng.site,http://13.125.200.221
MAIL_USERNAME=youjiyeon4@gmail.com
MAIL_PASSWORD=hmqv wsha xdgs hdie
SPRING_JPA_HIBERNATE_DDL_AUTO=create-drop
SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA=seurasaeng-prod
EOF

echo "✅ .env 파일 생성 완료"

# 기존 컨테이너 중지 및 볼륨 정리
echo "🛑 기존 컨테이너 중지 및 정리..."
docker-compose down -v
docker system prune -f

# Docker 이미지 로드
if [ -f "../seurasaeng_be-image.tar.gz" ]; then
    echo "📦 Docker 이미지 로드..."
    docker load < ../seurasaeng_be-image.tar.gz
    rm -f ../seurasaeng_be-image.tar.gz
fi

# 새 컨테이너 시작
echo "▶️ 새 컨테이너 시작..."
docker-compose up -d

# 백엔드 시작 대기
echo "⏳ 백엔드 시작 대기 중..."
sleep 60

echo "✅ Backend 배포 완료!"