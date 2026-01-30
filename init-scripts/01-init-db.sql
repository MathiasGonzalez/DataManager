-- Initialize DataManager Database
-- This script runs automatically when the PostgreSQL container starts for the first time

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create a schema for the application
CREATE SCHEMA IF NOT EXISTS datamanager;

-- Set the default search path
ALTER DATABASE datamanager_db SET search_path TO datamanager, public;

-- Create a sample table structure (customize based on your needs)
CREATE TABLE IF NOT EXISTS datamanager.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS datamanager.data_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES datamanager.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON datamanager.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON datamanager.users(email);
CREATE INDEX IF NOT EXISTS idx_data_entries_user_id ON datamanager.data_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_data_entries_created_at ON datamanager.data_entries(created_at);
CREATE INDEX IF NOT EXISTS idx_data_entries_metadata ON datamanager.data_entries USING gin(metadata);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION datamanager.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON datamanager.users
    FOR EACH ROW EXECUTE FUNCTION datamanager.update_updated_at_column();

CREATE TRIGGER update_data_entries_updated_at BEFORE UPDATE ON datamanager.data_entries
    FOR EACH ROW EXECUTE FUNCTION datamanager.update_updated_at_column();

-- Grant privileges (adjust as needed)
GRANT USAGE ON SCHEMA datamanager TO datamanager;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA datamanager TO datamanager;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA datamanager TO datamanager;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA datamanager TO datamanager;

-- Insert sample data (optional - for testing)
INSERT INTO datamanager.users (username, email) VALUES
    ('admin', 'admin@datamanager.com'),
    ('testuser', 'test@datamanager.com')
ON CONFLICT (username) DO NOTHING;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'DataManager database initialization completed successfully';
END $$;
