#!/bin/bash

# DataManager PostgreSQL Health Check Script
# This script checks if the PostgreSQL database is ready to accept connections

set -e

echo "Checking PostgreSQL connection..."

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Default values
POSTGRES_USER=${POSTGRES_USER:-datamanager}
POSTGRES_DB=${POSTGRES_DB:-datamanager_db}
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

# Check if PostgreSQL is running
if docker compose ps | grep -q "datamanager-postgres.*Up"; then
    echo "✓ PostgreSQL container is running"
else
    echo "✗ PostgreSQL container is not running"
    exit 1
fi

# Check if PostgreSQL is accepting connections
if docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" > /dev/null 2>&1; then
    echo "✓ PostgreSQL is accepting connections"
else
    echo "✗ PostgreSQL is not accepting connections"
    exit 1
fi

# Check if database exists and is accessible
if docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✓ Database '$POSTGRES_DB' is accessible"
else
    echo "✗ Database '$POSTGRES_DB' is not accessible"
    exit 1
fi

# Check if schema exists
if docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'datamanager';" | grep -q "datamanager"; then
    echo "✓ Schema 'datamanager' exists"
else
    echo "⚠ Schema 'datamanager' does not exist"
fi

# Check if tables exist
TABLE_COUNT=$(docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'datamanager';" | tr -d ' ')
if [ "$TABLE_COUNT" -gt 0 ]; then
    echo "✓ Found $TABLE_COUNT tables in 'datamanager' schema"
else
    echo "⚠ No tables found in 'datamanager' schema"
fi

# Check pgAdmin
if docker compose ps | grep -q "datamanager-pgadmin.*Up"; then
    echo "✓ pgAdmin container is running"
else
    echo "⚠ pgAdmin container is not running"
fi

echo ""
echo "Health check completed successfully!"
echo ""
echo "Connection details:"
echo "  Host: $POSTGRES_HOST"
echo "  Port: $POSTGRES_PORT"
echo "  Database: $POSTGRES_DB"
echo "  User: $POSTGRES_USER"
echo ""
echo "Access pgAdmin at: http://localhost:${PGADMIN_PORT:-5050}"
