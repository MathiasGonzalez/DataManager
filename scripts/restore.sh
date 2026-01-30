#!/bin/sh
# ============================================
# PostgreSQL Restore Script
# ============================================
# This script restores a PostgreSQL database backup
# from a .sql or .sql.gz file in the /backups directory.

set -e

# Configuration from environment variables
DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="${POSTGRES_DB:-datamanager}"
DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
BACKUP_DIR="/backups"

# Try to resolve hostname, fallback to getent or direct connection
if ! ping -c 1 -W 1 ${DB_HOST} >/dev/null 2>&1; then
    # Try to get IP from /etc/hosts or links
    DB_IP=$(grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(datamanager_)?postgres" /etc/hosts | head -1 | awk '{print $1}')
    if [ -n "$DB_IP" ]; then
        DB_HOST="$DB_IP"
    fi
fi

# Check if backup file was provided as argument
if [ -z "$1" ]; then
    echo "============================================"
    echo "PostgreSQL Restore Script"
    echo "============================================"
    echo "Usage: docker compose exec db_utils restore.sh <backup_file>"
    echo ""
    echo "Available backups in ${BACKUP_DIR}:"
    ls -lh ${BACKUP_DIR}/*.sql* 2>/dev/null || echo "No backup files found"
    echo "============================================"
    echo "Example:"
    echo "  docker compose exec db_utils restore.sh /backups/datamanager_backup_20240101_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

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

# Determine if file is compressed
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    echo "Decompressing and restoring from compressed backup..."
    gunzip -c ${BACKUP_FILE} | psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -v ON_ERROR_STOP=1
else
    echo "Restoring from uncompressed backup..."
    psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -v ON_ERROR_STOP=1 -f ${BACKUP_FILE}
fi

# Check if restore was successful
if [ $? -eq 0 ]; then
    echo "============================================"
    echo "✓ Restore completed successfully!"
    echo "============================================"
    
    # Display database size
    echo "Current database size:"
    psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "\l+ ${DB_NAME}"
else
    echo "============================================"
    echo "✗ Restore failed"
    echo "============================================"
    exit 1
fi
