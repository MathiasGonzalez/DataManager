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
