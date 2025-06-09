# 멀티 스테이지 빌드 - Builder Stage
FROM node:18-alpine as builder

WORKDIR /app

# package.json과 package-lock.json 복사 (의존성 캐싱 최적화)
COPY package*.json ./

# 의존성 설치 (dev 의존성도 포함 - Vite와 Tailwind 빌드 도구 필요)
RUN npm ci

# 소스 코드 복사
COPY . .

# Vite 환경변수 설정 (빌드시 적용) - HTTPS로 변경
ARG VITE_API_URL=https://seurasaeng.site/api
ENV VITE_API_URL=$VITE_API_URL

# React 앱 빌드 (Vite)
RUN npm run build

# 빌드 결과 확인 (디버깅용)
RUN ls -la dist/

# Nginx 이미지로 프로덕션 환경 구성
FROM nginx:1.25-alpine

# 필수 패키지 설치 (curl, openssl 포함)
RUN apk add --no-cache curl tzdata openssl && \
    cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    echo "Asia/Seoul" > /etc/timezone && \
    apk del tzdata

# SSL 디렉토리 생성
RUN mkdir -p /etc/letsencrypt/live/seurasaeng.site \
             /var/www/certbot \
             /var/log/nginx

# 사용자 정의 Nginx 설정 복사
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# 빌드된 React 앱 복사 (Vite는 dist 폴더에 빌드)
COPY --from=builder /app/dist /usr/share/nginx/html

# index.html이 존재하는지 확인 (디버깅용)
RUN ls -la /usr/share/nginx/html/

# 정적 파일 권한 설정
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# 로그 및 SSL 디렉토리 권한 설정
RUN chown -R nginx:nginx /var/log/nginx /var/www/certbot && \
    chmod -R 755 /var/www/certbot

# 포트 노출
EXPOSE 80 443

# 헬스체크 (HTTPS 지원)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f https://localhost/health -k || curl -f http://localhost/health || exit 1

# SSL 인증서 확인 스크립트 생성
RUN echo '#!/bin/sh' > /docker-entrypoint.d/10-check-ssl.sh && \
    echo 'if [ ! -f /etc/letsencrypt/live/seurasaeng.site/fullchain.pem ]; then' >> /docker-entrypoint.d/10-check-ssl.sh && \
    echo '  echo "SSL certificates not found. Creating self-signed certificate for initial setup..."' >> /docker-entrypoint.d/10-check-ssl.sh && \
    echo '  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \' >> /docker-entrypoint.d/10-check-ssl.sh && \
    echo '    -keyout /etc/letsencrypt/live/seurasaeng.site/privkey.pem \' >> /docker-entrypoint.d/10-check-ssl.sh && \
    echo '    -out /etc/letsencrypt/live/seurasaeng.site/fullchain.pem \' >> /docker-entrypoint.d/10-check-ssl.sh && \
    echo '    -subj "/C=KR/ST=Seoul/L=Seoul/O=Seurasaeng/CN=seurasaeng.site"' >> /docker-entrypoint.d/10-check-ssl.sh && \
    echo '  cp /etc/letsencrypt/live/seurasaeng.site/fullchain.pem /etc/letsencrypt/live/seurasaeng.site/chain.pem' >> /docker-entrypoint.d/10-check-ssl.sh && \
    echo 'fi' >> /docker-entrypoint.d/10-check-ssl.sh && \
    chmod +x /docker-entrypoint.d/10-check-ssl.sh

# Nginx 시작
CMD ["nginx", "-g", "daemon off;"]