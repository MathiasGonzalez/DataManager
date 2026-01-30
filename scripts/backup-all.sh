#!/bin/sh
# ============================================
# PostgreSQL Backup All Databases Script
# ============================================
# This script creates backups of all non-system databases
# using pg_dump and saves them to the /backups directory.

set -e

# Configuration from environment variables
DB_USER="${POSTGRES_USER:-postgres}"
DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
BACKUP_DIR="/backups"

# Try to resolve hostname, fallback to IP
if ! ping -c 1 -W 1 ${DB_HOST} >/dev/null 2>&1; then
    DB_IP=$(grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+postgres" /etc/hosts | head -1 | awk '{print $1}')
    if [ -n "$DB_IP" ]; then
        DB_HOST="$DB_IP"
    fi
fi

# Generate timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "============================================"
echo "Starting PostgreSQL Backup - ALL DATABASES"
echo "============================================"
echo "Host: ${DB_HOST}:${DB_PORT}"
echo "User: ${DB_USER}"
echo "Timestamp: ${TIMESTAMP}"
echo "============================================"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Get list of all databases except system databases
echo "Fetching database list..."
DATABASES=$(psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres', 'template0', 'template1');")

if [ -z "$DATABASES" ]; then
    echo "⚠ No user databases found to backup."
    echo "Only system databases (postgres, template0, template1) exist."
    exit 0
fi

# Count total databases
TOTAL_DBS=$(echo "$DATABASES" | wc -l)
CURRENT=0
FAILED=0
SUCCESS=0

echo "Found ${TOTAL_DBS} database(s) to backup:"
echo "$DATABASES"
echo "============================================"

# Backup each database
for DB_NAME in $DATABASES; do
    # Trim whitespace
    DB_NAME=$(echo "$DB_NAME" | xargs)
    
    if [ -z "$DB_NAME" ]; then
        continue
    fi
    
    CURRENT=$((CURRENT + 1))
    
    echo ""
    echo "[$CURRENT/$TOTAL_DBS] Backing up database: ${DB_NAME}"
    echo "--------------------------------------------"
    
    BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.sql"
    BACKUP_FILE_COMPRESSED="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.sql.gz"
    
    # Perform backup
    if pg_dump -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} \
        --format=plain \
        --no-owner \
        --no-acl \
        --file=${BACKUP_FILE} 2>&1; then
        
        # Compress the backup
        if gzip ${BACKUP_FILE} 2>&1; then
            SIZE=$(du -h ${BACKUP_FILE_COMPRESSED} | cut -f1)
            echo "✓ ${DB_NAME}: Success (${SIZE})"
            SUCCESS=$((SUCCESS + 1))
        else
            echo "✗ ${DB_NAME}: Compression failed"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "✗ ${DB_NAME}: Backup failed"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "============================================"
echo "Backup Summary"
echo "============================================"
echo "Total databases: ${TOTAL_DBS}"
echo "Successful: ${SUCCESS}"
echo "Failed: ${FAILED}"
echo "============================================"

# Optional: Remove old backups (keep last 7 days)
echo "Cleaning up old backups (keeping last 7 days)..."
find ${BACKUP_DIR} -name "*_backup_*.sql.gz" -type f -mtime +7 -delete
echo "✓ Cleanup completed"

echo ""
echo "============================================"
echo "All backups in ${BACKUP_DIR}:"
echo "============================================"
ls -lh ${BACKUP_DIR}/*_backup_*.sql.gz 2>/dev/null || echo "No backups found"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
