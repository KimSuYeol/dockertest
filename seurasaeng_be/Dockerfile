# 멀티 스테이지 빌드 - Builder Stage
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app

# Maven Wrapper 복사 (있다면)
COPY mvnw* ./
COPY .mvn .mvn

# pom.xml 복사 (의존성 캐싱 최적화)
COPY pom.xml ./

# 의존성 다운로드
RUN chmod +x mvnw || true
RUN ./mvnw dependency:go-offline -B || mvn dependency:go-offline -B

# 소스 코드 복사
COPY src ./src

# Spring Boot 애플리케이션 빌드
RUN ./mvnw clean package -DskipTests -B || mvn clean package -DskipTests -B

# 빌드 결과 확인
RUN ls -la target/

# Production Stage - Eclipse Temurin 21 JRE (안정적인 공식 배포판)
FROM eclipse-temurin:21-jre

# 한국 시간대 설정
RUN apt-get update && \
    apt-get install -y tzdata curl && \
    ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    echo "Asia/Seoul" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 애플리케이션 사용자 생성
RUN groupadd -r spring && useradd -r -g spring spring

# 애플리케이션 디렉토리 생성
WORKDIR /app

# 빌드된 JAR 파일 복사
COPY --from=builder /app/target/seurasaeng-0.0.1-SNAPSHOT.jar app.jar

# 로그 디렉토리 생성
RUN mkdir -p /app/logs && \
    chown -R spring:spring /app

# 애플리케이션 사용자로 전환
USER spring

# JVM 최적화 환경변수
ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseG1GC"

# 포트 노출
EXPOSE 8080

# 헬스체크 설정
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 애플리케이션 시작 (간단하게)
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]