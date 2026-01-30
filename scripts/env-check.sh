#!/bin/sh
# ============================================
# Environment Variables Validation Script
# ============================================
# This script validates that all required environment variables
# are properly set before starting the PostgreSQL services.
#
# Usage: env-check.sh [--strict]
#   --strict: Exit with error on warnings

set -e

STRICT_MODE=0
if [ "$1" = "--strict" ]; then
    STRICT_MODE=1
fi

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "============================================"
echo "PostgreSQL Environment Validation"
echo "============================================"
echo ""

# Helper functions
error() {
    printf "${RED}✗ ERROR: %s${NC}\n" "$1"
    ERRORS=$((ERRORS + 1))
}

warning() {
    printf "${YELLOW}⚠ WARNING: %s${NC}\n" "$1"
    WARNINGS=$((WARNINGS + 1))
}

success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

info() {
    printf "  %s\n" "$1"
}

# Check if .env file exists
echo "Checking .env file..."
if [ ! -f ".env" ]; then
    error ".env file not found!"
    info "Create one by copying .env.example:"
    info "  cp .env.example .env"
    echo ""
else
    success ".env file exists"
    echo ""
fi

# Source .env file if it exists
if [ -f ".env" ]; then
    # Export variables from .env
    set -a
    . ./.env
    set +a
fi

# ============================================
# Validate PostgreSQL Configuration
# ============================================
echo "Validating PostgreSQL configuration..."

# Check POSTGRES_USER
if [ -z "$POSTGRES_USER" ]; then
    error "POSTGRES_USER is not set"
else
    success "POSTGRES_USER is set: $POSTGRES_USER"
fi

# Check POSTGRES_PASSWORD
if [ -z "$POSTGRES_PASSWORD" ]; then
    error "POSTGRES_PASSWORD is not set"
elif [ "$POSTGRES_PASSWORD" = "postgres" ]; then
    warning "POSTGRES_PASSWORD is using default value 'postgres'"
    info "Change this to a secure password for production!"
elif [ "$POSTGRES_PASSWORD" = "CHANGE_THIS_SECURE_PASSWORD_NOW" ]; then
    error "POSTGRES_PASSWORD still has placeholder value"
    info "Set a secure password in your .env file"
elif [ ${#POSTGRES_PASSWORD} -lt 8 ]; then
    warning "POSTGRES_PASSWORD is too short (less than 8 characters)"
    info "Use a stronger password for production"
else
    success "POSTGRES_PASSWORD is set (length: ${#POSTGRES_PASSWORD} chars)"
fi

# Check POSTGRES_DB
if [ -z "$POSTGRES_DB" ]; then
    warning "POSTGRES_DB is not set (will use default: postgres)"
else
    success "POSTGRES_DB is set: $POSTGRES_DB"
fi

# Check POSTGRES_PORT
if [ -z "$POSTGRES_PORT" ]; then
    warning "POSTGRES_PORT is not set (will use default: 5432)"
else
    success "POSTGRES_PORT is set: $POSTGRES_PORT"
fi

echo ""

# ============================================
# Validate PgBouncer Configuration
# ============================================
echo "Validating PgBouncer configuration..."

if [ -z "$PGBOUNCER_PORT" ]; then
    warning "PGBOUNCER_PORT is not set (will use default: 6432)"
else
    success "PGBOUNCER_PORT is set: $PGBOUNCER_PORT"
fi

if [ -n "$PGBOUNCER_MAX_CLIENT_CONN" ]; then
    success "PGBOUNCER_MAX_CLIENT_CONN is set: $PGBOUNCER_MAX_CLIENT_CONN"
fi

echo ""

# ============================================
# Validate PgAdmin Configuration
# ============================================
echo "Validating PgAdmin configuration..."

if [ -z "$PGADMIN_EMAIL" ]; then
    warning "PGADMIN_EMAIL is not set (will use default)"
else
    success "PGADMIN_EMAIL is set: $PGADMIN_EMAIL"
fi

if [ -z "$PGADMIN_PASSWORD" ]; then
    error "PGADMIN_PASSWORD is not set"
elif [ "$PGADMIN_PASSWORD" = "admin" ]; then
    warning "PGADMIN_PASSWORD is using default weak value"
    info "Change this to a secure password for production!"
elif [ ${#PGADMIN_PASSWORD} -lt 6 ]; then
    warning "PGADMIN_PASSWORD is too short"
else
    success "PGADMIN_PASSWORD is set (length: ${#PGADMIN_PASSWORD} chars)"
fi

if [ -z "$PGADMIN_PORT" ]; then
    warning "PGADMIN_PORT is not set (will use default: 5050)"
else
    success "PGADMIN_PORT is set: $PGADMIN_PORT"
fi

echo ""

# ============================================
# Security Checks
# ============================================
echo "Security checks..."

# Check if running as root
if [ "$(id -u)" = "0" ]; then
    warning "Running as root user"
    info "Consider running Docker as non-root user for better security"
fi

# Check if ports conflict
if [ "$POSTGRES_PORT" = "$PGBOUNCER_PORT" ]; then
    error "POSTGRES_PORT and PGBOUNCER_PORT are the same!"
    info "These must be different ports"
fi

if [ "$POSTGRES_PORT" = "$PGADMIN_PORT" ]; then
    error "POSTGRES_PORT and PGADMIN_PORT are the same!"
    info "These must be different ports"
fi

if [ "$PGBOUNCER_PORT" = "$PGADMIN_PORT" ]; then
    error "PGBOUNCER_PORT and PGADMIN_PORT are the same!"
    info "These must be different ports"
fi

echo ""

# ============================================
# Summary
# ============================================
echo "============================================"
echo "Validation Summary"
echo "============================================"
printf "${RED}Errors: %d${NC}\n" "$ERRORS"
printf "${YELLOW}Warnings: %d${NC}\n" "$WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
    printf "${RED}✗ Validation FAILED${NC}\n"
    echo "Please fix the errors above before starting the services."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    if [ $STRICT_MODE -eq 1 ]; then
        printf "${YELLOW}⚠ Validation completed with warnings (strict mode)${NC}\n"
        echo "Fix warnings or run without --strict flag."
        exit 1
    else
        printf "${YELLOW}⚠ Validation completed with warnings${NC}\n"
        echo "Review warnings above. Services can start but may not be production-ready."
        exit 0
    fi
else
    printf "${GREEN}✓ Validation PASSED${NC}\n"
    echo "All environment variables are properly configured!"
    exit 0
fi
