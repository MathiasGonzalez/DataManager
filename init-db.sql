-- ============================================
-- Database Initialization Script
-- ============================================
-- This script runs automatically when the PostgreSQL container
-- is created for the first time.

-- Enable UUID extension for generating unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_stat_statements for query performance monitoring
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================
-- Initial Schema (Optional - Customize as needed)
-- ============================================

-- Example: Create a sample schema
CREATE SCHEMA IF NOT EXISTS app;

-- Example: Create a sample table with UUID primary key
CREATE TABLE IF NOT EXISTS app.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Example: Create an index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON app.users(email);

-- Example: Create a sample table for audit logs
CREATE TABLE IF NOT EXISTS app.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    action VARCHAR(20) NOT NULL,
    user_id UUID,
    changed_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Performance Tuning Settings
-- ============================================

-- Configure pg_stat_statements to track more queries
ALTER SYSTEM SET pg_stat_statements.track = 'all';
ALTER SYSTEM SET pg_stat_statements.max = 10000;

-- ============================================
-- Informational Messages
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully';
    RAISE NOTICE 'Extensions enabled: uuid-ossp, pg_stat_statements';
    RAISE NOTICE 'Sample schema created: app';
    RAISE NOTICE 'Sample tables created: app.users, app.audit_logs';
END $$;
