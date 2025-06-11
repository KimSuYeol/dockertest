# 멀티 스테이지 빌드 - Builder Stage
FROM maven:3.9.4-eclipse-temurin-21 AS builder

WORKDIR /app

# pom.xml 먼저 복사 (의존성 캐싱 최적화)
COPY pom.xml ./

# 의존성 다운로드 (캐시 최적화)
RUN mvn dependency:go-offline -B

# 소스 코드 복사
COPY src ./src

# Spring Boot 애플리케이션 빌드
RUN mvn clean package -DskipTests -B

# 빌드 결과 확인
RUN ls -la target/

# Production Stage - Eclipse Temurin 21 JRE
FROM eclipse-temurin:21-jre-alpine

# 필요한 패키지 설치 및 한국 시간대 설정
RUN apk add --no-cache \
    tzdata \
    curl \
    bash \
    && cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo "Asia/Seoul" > /etc/timezone \
    && apk del tzdata

# 애플리케이션 사용자 생성
RUN addgroup -g 1001 -S spring && \
    adduser -u 1001 -S spring -G spring

# 애플리케이션 디렉토리 생성
WORKDIR /app

# 빌드된 JAR 파일 복사
COPY --from=builder /app/target/seurasaeng-0.0.1-SNAPSHOT.jar app.jar

# 로그 디렉토리 생성 및 권한 설정
RUN mkdir -p /app/logs && \
    chown -R spring:spring /app && \
    chmod 755 /app/logs

# 애플리케이션 사용자로 전환
USER spring

# JVM 최적화 환경변수 (단순화)
ENV JAVA_OPTS="-server \
    -Xmx512m \
    -Xms256m \
    -XX:+UseG1GC \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -Djava.security.egd=file:/dev/./urandom \
    -Duser.timezone=Asia/Seoul"

# 포트 노출
EXPOSE 8080

# 헬스체크 설정
HEALTHCHECK --interval=30s \
    --timeout=10s \
    --start-period=90s \
    --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# 애플리케이션 시작
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]