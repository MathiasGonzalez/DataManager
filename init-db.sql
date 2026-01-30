-- ============================================
-- PostgreSQL Server Initialization Script
-- ============================================
-- This script runs automatically when the PostgreSQL container
-- is created for the first time. It sets up common extensions
-- and configurations that will be available to all databases.

-- ============================================
-- Enable Common Extensions (in template1)
-- ============================================
-- These extensions will be available for all new databases

\c template1

-- Enable UUID extension for generating unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_stat_statements for query performance monitoring
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Enable other useful extensions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- Trigram matching for text search
CREATE EXTENSION IF NOT EXISTS "btree_gist";     -- Additional index types
CREATE EXTENSION IF NOT EXISTS "hstore";         -- Key-value store

-- ============================================
-- Performance Tuning Settings
-- ============================================

-- Configure pg_stat_statements to track more queries
ALTER SYSTEM SET pg_stat_statements.track = 'all';
ALTER SYSTEM SET pg_stat_statements.max = 10000;

-- Additional performance settings for multi-database server
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';

-- ============================================
-- Informational Messages
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'PostgreSQL Multi-Project Server Initialized';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Extensions enabled in template1:';
    RAISE NOTICE '  - uuid-ossp (UUID generation)';
    RAISE NOTICE '  - pg_stat_statements (query monitoring)';
    RAISE NOTICE '  - pg_trgm (text search)';
    RAISE NOTICE '  - btree_gist (indexing)';
    RAISE NOTICE '  - hstore (key-value storage)';
    RAISE NOTICE '';
    RAISE NOTICE 'Performance tuning configured for multi-project usage';
    RAISE NOTICE '';
    RAISE NOTICE 'To create a new database for a project:';
    RAISE NOTICE '  CREATE DATABASE myproject_db;';
    RAISE NOTICE '';
    RAISE NOTICE 'All extensions will be available in new databases.';
    RAISE NOTICE '==============================================';
END $$;
