#!/bin/sh
# ============================================
# PostgreSQL Restore Script
# ============================================
# This script restores a PostgreSQL database backup
# from a .sql or .sql.gz file in the /backups directory.
#
# Usage: restore.sh <backup_file> [database_name]
#   If database_name is not provided, uses POSTGRES_DB env variable

set -e

# Configuration from environment variables
DB_USER="${POSTGRES_USER:-postgres}"
DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
BACKUP_DIR="/backups"

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

# Check if backup file was provided as argument
if [ -z "$1" ]; then
    echo "============================================"
    echo "PostgreSQL Restore Script"
    echo "============================================"
    echo "Usage: restore.sh <backup_file> [database_name]"
    echo ""
    echo "Available backups in ${BACKUP_DIR}:"
    ls -lh "${BACKUP_DIR}"/*.sql* 2>/dev/null || echo "No backup files found"
    echo "============================================"
echo "Examples:"
echo "  # Restore to database specified in backup filename or POSTGRES_DB env var:"
echo "  docker compose --profile tools run --rm db_utils restore.sh /backups/myproject_backup_20240101_120000.sql.gz"
echo ""
echo "  # Restore to specific database:"
echo "  docker compose --profile tools run --rm db_utils restore.sh /backups/myproject_backup_20240101_120000.sql.gz myproject_db"
    exit 1
fi

BACKUP_FILE="$1"

# Get database name from second argument or try to extract from filename or use env var
if [ -n "$2" ]; then
    DB_NAME="$2"
else
    # Try to extract database name from backup filename (e.g., mydb_backup_20240101.sql.gz -> mydb)
    FILENAME=$(basename "$BACKUP_FILE")
    DB_NAME=$(echo "$FILENAME" | sed 's/_backup_.*$//')
    
    # If extraction failed or resulted in empty string, use env variable
    if [ -z "$DB_NAME" ] || [ "$DB_NAME" = "$FILENAME" ]; then
        DB_NAME="${POSTGRES_DB:-postgres}"
    fi
fi

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "✗ Error: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "============================================"
echo "Starting PostgreSQL Restore"
echo "============================================"
echo "Database: ${DB_NAME}"
echo "Host: ${DB_HOST}:${DB_PORT}"
echo "User: ${DB_USER}"
echo "Backup file: ${BACKUP_FILE}"
echo "============================================"

# Warning prompt
echo "⚠ WARNING: This will restore the database from backup."
echo "⚠ All current data in '${DB_NAME}' will be replaced."
echo "⚠ Make sure you have a recent backup before proceeding."
echo ""
echo "Proceeding with restore in 5 seconds... (Press Ctrl+C to cancel)"
sleep 5

restore_result=0
case "${BACKUP_FILE}" in
    *.gz)
        echo "Decompressing and restoring from compressed backup..."
        gunzip -c "${BACKUP_FILE}" | psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 || restore_result=1
        ;;
    *)
        echo "Restoring from uncompressed backup..."
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -f "${BACKUP_FILE}" || restore_result=1
        ;;
esac

if [ $restore_result -eq 0 ]; then
    echo "============================================"
    echo "Restore completed successfully!"
    echo "============================================"
    
    echo "Current database size:"
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "\l+ ${DB_NAME}"
else
    echo "============================================"
    echo "Restore failed"
    echo "============================================"
    exit 1
fi
