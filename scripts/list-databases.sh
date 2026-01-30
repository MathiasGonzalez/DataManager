#!/bin/sh
# ============================================
# PostgreSQL List Databases Script
# ============================================
# This script lists all databases on the PostgreSQL server
# with size information and access details.

set -e

# Configuration from environment variables
DB_USER="${POSTGRES_USER:-postgres}"
DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"

resolve_host() {
    if command -v getent >/dev/null 2>&1; then
        getent hosts "$1" 2>/dev/null | awk '{print $1}' | head -1
    else
        grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+$1" /etc/hosts 2>/dev/null | head -1 | awk '{print $1}'
    fi
}

DB_RESOLVED=$(resolve_host "${DB_HOST}")
if [ -n "$DB_RESOLVED" ]; then
    DB_HOST="$DB_RESOLVED"
fi

echo "============================================"
echo "PostgreSQL Databases"
echo "============================================"
echo "Server: ${DB_HOST}:${DB_PORT}"
echo "User: ${DB_USER}"
echo "============================================"
echo ""

# List all databases with size information
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "
SELECT 
    d.datname AS \"Database\",
    pg_catalog.pg_get_userbyid(d.datdba) AS \"Owner\",
    CASE 
        WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
        THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
        ELSE 'No Access'
    END AS \"Size\",
    d.datconnlimit AS \"Conn Limit\",
    CASE 
        WHEN d.datistemplate THEN 'Template'
        WHEN d.datname IN ('postgres') THEN 'System'
        ELSE 'User'
    END AS \"Type\"
FROM pg_catalog.pg_database d
ORDER BY 
    CASE 
        WHEN d.datname IN ('postgres', 'template0', 'template1') THEN 0
        ELSE 1
    END,
    pg_catalog.pg_database_size(d.datname) DESC;
"

echo ""
echo "============================================"
echo "Active Connections by Database"
echo "============================================"

psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "
SELECT 
    datname AS \"Database\",
    COUNT(*) AS \"Connections\"
FROM pg_stat_activity
WHERE datname IS NOT NULL
GROUP BY datname
ORDER BY COUNT(*) DESC;
"

echo ""
echo "============================================"
echo "Quick Commands"
echo "============================================"
echo "Create new database:"
echo "  docker compose exec db_utils psql -h postgres -U postgres -c \"CREATE DATABASE myproject_db;\""
echo ""
echo "Backup specific database:"
echo "  docker compose exec db_utils backup.sh myproject_db"
echo ""
echo "Backup all databases:"
echo "  docker compose exec db_utils backup-all.sh"
echo ""
echo "Connect to database:"
echo "  docker compose exec db_utils psql -h postgres -U postgres -d myproject_db"
echo "============================================"
