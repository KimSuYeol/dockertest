-- PostgreSQL 초기화 스크립트
-- 데이터베이스: postgres
-- 스키마: seurasaeng_prod, seurasaeng_test

-- UTF-8 인코딩 설정
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

\echo 'Creating schemas seurasaeng_prod and seurasaeng_test...'

-- 스키마 생성
CREATE SCHEMA IF NOT EXISTS "seurasaeng_prod";
CREATE SCHEMA IF NOT EXISTS "seurasaeng_test";

-- 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA "seurasaeng_prod" TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA "seurasaeng_test" TO postgres;

-- 각 스키마에 대한 사용 권한 부여
GRANT USAGE ON SCHEMA "seurasaeng_prod" TO postgres;
GRANT USAGE ON SCHEMA "seurasaeng_test" TO postgres;

-- 미래에 생성될 테이블들에 대한 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_prod" GRANT ALL PRIVILEGES ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_test" GRANT ALL PRIVILEGES ON TABLES TO postgres;

-- 시퀀스에 대한 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_prod" GRANT ALL PRIVILEGES ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_test" GRANT ALL PRIVILEGES ON SEQUENCES TO postgres;

-- 함수에 대한 권한 부여
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_prod" GRANT ALL PRIVILEGES ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA "seurasaeng_test" GRANT ALL PRIVILEGES ON FUNCTIONS TO postgres;

-- 기본 스키마 설정 (test를 기본으로)
ALTER USER postgres SET search_path TO seurasaeng_test,seurasaeng_prod,public;

-- 확장 기능 설치 (필요한 경우)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 연결 정보 로그
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL 초기화 완료';
    RAISE NOTICE '생성된 스키마: seurasaeng_prod, seurasaeng_test';
    RAISE NOTICE '데이터베이스: %', current_database();
    RAISE NOTICE '현재 사용자: %', current_user;
    RAISE NOTICE '현재 시간: %', now();
END $$;