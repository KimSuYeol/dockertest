# 멀티 스테이지 빌드 - Builder Stage
FROM node:18-alpine as builder

WORKDIR /app

# package.json과 package-lock.json 복사 (의존성 캐싱 최적화)
COPY package*.json ./

# 의존성 설치 (dev 의존성도 포함 - Vite와 Tailwind 빌드 도구 필요)
RUN npm ci

# 소스 코드 복사
COPY . .

# Vite 환경변수 설정 (빌드시 적용)
ARG VITE_API_URL=http://13.125.200.221/api
ENV VITE_API_URL=$VITE_API_URL

# React 앱 빌드 (Vite)
RUN npm run build

# 빌드 결과 확인 (디버깅용)
RUN ls -la dist/

# Nginx 이미지로 프로덕션 환경 구성
FROM nginx:1.25-alpine

# 필수 패키지 설치 (curl 포함)
RUN apk add --no-cache curl tzdata && \
    cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    echo "Asia/Seoul" > /etc/timezone && \
    apk del tzdata

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

# 로그 디렉토리 생성
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx

# 포트 노출
EXPOSE 80 443

# 헬스체크 (curl 사용)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Nginx 시작
CMD ["nginx", "-g", "daemon off;"]