FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG VITE_API_URL=https://seurasaeng.site/api
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

FROM nginx:1.25-alpine
ARG DOMAIN=seurasaeng.site
ARG EMAIL=admin@seurasaeng.site
ENV DOMAIN=$DOMAIN EMAIL=$EMAIL AUTO_SSL=true

RUN apk add --no-cache curl openssl tzdata bash certbot \
    && cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo "Asia/Seoul" > /etc/timezone \
    && apk del tzdata

RUN mkdir -p /etc/ssl/certs /etc/ssl/private /var/www/certbot/.well-known/acme-challenge /var/log/nginx /var/log/letsencrypt /scripts \
    && chmod -R 755 /var/www/certbot \
    && chmod 755 /etc/ssl/certs \
    && chmod 700 /etc/ssl/private

COPY nginx/ /etc/nginx/
COPY --from=builder /app/dist /usr/share/nginx/html
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh && chmod -R 755 /usr/share/nginx/html

EXPOSE 80 443
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f https://localhost/health -k || curl -f http://localhost/health || exit 1
CMD ["/scripts/start.sh"]