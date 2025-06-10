-- PostgreSQL 초기화 스크립트
-- 데이터베이스: seuraseung
-- 스키마: seurasaeng-prod, seurasaeng-test, seurasaeng_test (언더스코어 버전 추가)

-- UTF-8 인코딩 설정
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- 스키마 생성 (기존 + 새로 추가)
CREATE SCHEMA IF NOT EXISTS "seurasaeng-prod";
CREATE SCHEMA IF NOT EXISTS "seurasaeng-test";
CREATE SCHEMA IF NOT EXISTS "seurasaeng_test";  -- 🔥 추가: Entity에서 사용하는 스키마

-- 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA "seurasaeng-prod" TO seuraseung;
GRANT ALL PRIVILEGES ON SCHEMA "seurasaeng-test" TO seuraseung;
GRANT ALL PRIVILEGES ON SCHEMA "seurasaeng_test" TO seuraseung;  -- 🔥 추가

-- 각 스키마에 대한 사용 권한 부여
GRANT USAGE ON SCHEMA "seurasaeng-prod" TO seuraseung;
GRANT USAGE ON SCHEMA "seurasaeng-test" TO seuraseung;
GRANT USAGE ON SCHEMA "seurasaeng_test" TO seuraseung;  -- 🔥 추가

-- 미래에 생성될 테이블들에 대한 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng-prod" GRANT ALL PRIVILEGES ON TABLES TO seuraseung;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng-test" GRANT ALL PRIVILEGES ON TABLES TO seuraseung;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_test" GRANT ALL PRIVILEGES ON TABLES TO seuraseung;  -- 🔥 추가

-- 시퀀스에 대한 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng-prod" GRANT ALL PRIVILEGES ON SEQUENCES TO seuraseung;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng-test" GRANT ALL PRIVILEGES ON SEQUENCES TO seuraseung;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_test" GRANT ALL PRIVILEGES ON SEQUENCES TO seuraseung;  -- 🔥 추가

-- 함수에 대한 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng-prod" GRANT ALL PRIVILEGES ON FUNCTIONS TO seuraseung;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng-test" GRANT ALL PRIVILEGES ON FUNCTIONS TO seuraseung;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_test" GRANT ALL PRIVILEGES ON FUNCTIONS TO seuraseung;  -- 🔥 추가

-- 확장 기능 설치 (필요한 경우)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 연결 정보 로그
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL 초기화 완료';
    RAISE NOTICE '생성된 스키마: seurasaeng-prod, seurasaeng-test, seurasaeng_test';
    RAISE NOTICE '데이터베이스: %', current_database();
    RAISE NOTICE '현재 사용자: %', current_user;
    RAISE NOTICE '현재 시간: %', now();
END $$;