#!/bin/sh
# ============================================
# PostgreSQL Backup Script
# ============================================
# This script creates a backup of a PostgreSQL database
# using pg_dump and saves it to the /backups directory.
#
# Usage: backup.sh [database_name]
#   If database_name is not provided, uses POSTGRES_DB env variable

set -e

# Configuration from environment variables
DB_USER="${POSTGRES_USER:-postgres}"
DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
BACKUP_DIR="/backups"

# Get database name from argument or environment variable
if [ -n "$1" ]; then
    DB_NAME="$1"
else
    DB_NAME="${POSTGRES_DB:-postgres}"
fi

# Try to resolve hostname, fallback to getent or direct connection
if ! ping -c 1 -W 1 ${DB_HOST} >/dev/null 2>&1; then
    # Try to get IP from /etc/hosts or links
    DB_IP=$(grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+postgres" /etc/hosts | head -1 | awk '{print $1}')
    if [ -n "$DB_IP" ]; then
        DB_HOST="$DB_IP"
    fi
fi

# Generate timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.sql"
BACKUP_FILE_COMPRESSED="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.sql.gz"

echo "============================================"
echo "Starting PostgreSQL Backup"
echo "============================================"
echo "Database: ${DB_NAME}"
echo "Host: ${DB_HOST}:${DB_PORT}"
echo "User: ${DB_USER}"
echo "Timestamp: ${TIMESTAMP}"
echo "============================================"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Perform backup using pg_dump
echo "Creating backup..."
pg_dump -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} \
    --format=plain \
    --no-owner \
    --no-acl \
    --verbose \
    --file=${BACKUP_FILE}

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "✓ Backup created successfully: ${BACKUP_FILE}"
    
    # Compress the backup
    echo "Compressing backup..."
    gzip ${BACKUP_FILE}
    
    if [ $? -eq 0 ]; then
        echo "✓ Backup compressed: ${BACKUP_FILE_COMPRESSED}"
        
        # Calculate and display file size
        SIZE=$(du -h ${BACKUP_FILE_COMPRESSED} | cut -f1)
        echo "✓ Backup size: ${SIZE}"
        
        echo "============================================"
        echo "Backup completed successfully!"
        echo "============================================"
    else
        echo "✗ Failed to compress backup"
        exit 1
    fi
else
    echo "✗ Backup failed"
    exit 1
fi

# Optional: Remove old backups (keep last 7 days)
echo "Cleaning up old backups of ${DB_NAME} (keeping last 7 days)..."
find ${BACKUP_DIR} -name "${DB_NAME}_backup_*.sql.gz" -type f -mtime +7 -delete
echo "✓ Cleanup completed"

echo "============================================"
echo "Available backups for ${DB_NAME}:"
echo "============================================"
ls -lh ${BACKUP_DIR}/${DB_NAME}_backup_*.sql.gz 2>/dev/null || echo "No backups found for ${DB_NAME}"
