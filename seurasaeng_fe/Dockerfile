# 멀티 스테이지 빌드 - Builder Stage
FROM node:18-alpine as builder

WORKDIR /app

# 의존성 설치
COPY package*.json ./
RUN npm ci

# 소스 코드 복사 및 빌드
COPY . .
ARG VITE_API_URL=https://seurasaeng.site/api
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Production Stage
FROM nginx:1.25-alpine

# 빌드 인수
ARG DOMAIN=seurasaeng.site
ARG EMAIL=admin@seurasaeng.site

# 환경변수 설정
ENV DOMAIN=$DOMAIN \
    EMAIL=$EMAIL \
    AUTO_SSL=true

# 필수 패키지 설치
RUN apk add --no-cache \
    curl \
    openssl \
    tzdata \
    bash \
    certbot \
    && cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo "Asia/Seoul" > /etc/timezone \
    && apk del tzdata

# 디렉토리 생성
RUN mkdir -p \
    /etc/ssl/certs \
    /etc/ssl/private \
    /var/www/certbot \
    /var/log/nginx \
    /scripts

# Nginx 설정 복사
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# 빌드된 React 앱 복사
COPY --from=builder /app/dist /usr/share/nginx/html

# 스크립트 파일들 복사
COPY scripts/ /scripts/

# 스크립트 실행 권한 부여
RUN chmod +x /scripts/*.sh

# 권한 설정
RUN chown -R nginx:nginx /usr/share/nginx/html /var/log/nginx /var/www/certbot \
    && chmod -R 755 /usr/share/nginx/html /var/www/certbot

# 포트 노출
EXPOSE 80 443

# 헬스체크
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f https://localhost/health -k || curl -f http://localhost/health || exit 1

# 시작 명령
CMD ["/scripts/start.sh"]