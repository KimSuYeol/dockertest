# 멀티 스테이지 빌드 - Builder Stage (Maven 포함 이미지)
FROM maven:3.9.4-eclipse-temurin-21 AS builder

WORKDIR /app

# pom.xml과 Maven wrapper 복사 (의존성 캐싱 최적화)
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw ./

# Maven wrapper 실행 권한 부여
RUN chmod +x ./mvnw

# 의존성 다운로드 (캐시 최적화)
RUN ./mvnw dependency:go-offline -B

# 소스 코드 복사
COPY src ./src

# Spring Boot 애플리케이션 빌드
RUN ./mvnw clean package -DskipTests -B

# 빌드 결과 확인
RUN ls -la target/

# Production Stage - Eclipse Temurin 21 JRE (최적화된 이미지)
FROM eclipse-temurin:21-jre-alpine

# 필요한 패키지 설치 및 한국 시간대 설정
RUN apk add --no-cache \
    tzdata \
    curl \
    bash \
    && cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo "Asia/Seoul" > /etc/timezone \
    && apk del tzdata

# 애플리케이션 사용자 생성 (보안 강화)
RUN addgroup -g 1001 -S spring && \
    adduser -u 1001 -S spring -G spring

# 애플리케이션 디렉토리 생성
WORKDIR /app

# 방법 1: 와일드카드 사용 (현재 사용 중 - 권장)
COPY --from=builder /app/target/*.jar app.jar

# 방법 2: 메인 JAR만 정확히 복사 (더 안전한 대안)
# COPY --from=builder /app/target/*-SNAPSHOT.jar app.jar

# 방법 3: 실행 가능한 JAR만 복사 (가장 정확)
# RUN find /app/target -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" -exec cp {} app.jar \;

# 로그 디렉토리 생성 및 권한 설정
RUN mkdir -p /app/logs /app/temp && \
    chown -R spring:spring /app && \
    chmod 755 /app/logs /app/temp

# 애플리케이션 사용자로 전환
USER spring

# JVM 최적화 환경변수 (컨테이너 환경에 최적화)
ENV JAVA_OPTS="-server \
    -Xmx512m \
    -Xms256m \
    -XX:+UseG1GC \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:+OptimizeStringConcat \
    -XX:+UseStringDeduplication \
    -Djava.security.egd=file:/dev/./urandom \
    -Duser.timezone=Asia/Seoul \
    -Dspring.backgroundpreinitializer.ignore=true \
    -Djava.awt.headless=true"

# 포트 노출
EXPOSE 8080

# 헬스체크 설정 (더 신뢰성 있는 체크)
HEALTHCHECK --interval=30s \
    --timeout=10s \
    --start-period=60s \
    --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# 애플리케이션 시작 스크립트
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]

# 메타데이터 라벨
LABEL maintainer="seurasaeng-team" \
      version="1.0" \
      description="Seurasaeng Backend Application"