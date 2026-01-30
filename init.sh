#!/bin/bash
# ============================================
# PostgreSQL Multi-Project Server Initialization
# ============================================
# Idempotent initialization script for setting up the
# PostgreSQL Docker Compose environment.
#
# This script:
# - Checks prerequisites (Docker, Docker Compose)
# - Creates .env file if it doesn't exist
# - Validates environment variables
# - Creates necessary directories
# - Optionally starts the services
#
# Usage: ./init.sh [options]
#   --start       Start services after initialization
#   --stop        Stop services
#   --restart     Restart services
#   --status      Check services status
#   --validate    Only validate environment (don't start)
#   --help        Show this help message

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Parse arguments
START_SERVICES=0
STOP_SERVICES=0
RESTART_SERVICES=0
CHECK_STATUS=0
VALIDATE_ONLY=0

print_help() {
    echo "PostgreSQL Multi-Project Server Initialization"
    echo ""
    echo "Usage: ./init.sh [options]"
    echo ""
    echo "Options:"
    echo "  --start       Initialize and start services"
    echo "  --stop        Stop services"
    echo "  --restart     Restart services"
    echo "  --status      Check services status"
    echo "  --validate    Only validate environment (don't start)"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./init.sh                 # Initialize only"
    echo "  ./init.sh --start         # Initialize and start services"
    echo "  ./init.sh --validate      # Validate environment only"
    echo "  ./init.sh --status        # Check services status"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --start)
            START_SERVICES=1
            shift
            ;;
        --stop)
            STOP_SERVICES=1
            shift
            ;;
        --restart)
            RESTART_SERVICES=1
            shift
            ;;
        --status)
            CHECK_STATUS=1
            shift
            ;;
        --validate)
            VALIDATE_ONLY=1
            shift
            ;;
        --help)
            print_help
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            ;;
    esac
done

# Helper functions
error() {
    printf "${RED}✗ ERROR: %s${NC}\n" "$1"
}

warning() {
    printf "${YELLOW}⚠ WARNING: %s${NC}\n" "$1"
}

success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

info() {
    printf "${BLUE}ℹ %s${NC}\n" "$1"
}

section() {
    echo ""
    echo "============================================"
    echo "$1"
    echo "============================================"
}

# ============================================
# Check Prerequisites
# ============================================
section "Checking Prerequisites"

# Check Docker
if ! command -v docker &> /dev/null; then
    error "Docker is not installed!"
    info "Install Docker from: https://docs.docker.com/get-docker/"
    exit 1
else
    DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | sed 's/,//')
    success "Docker is installed (version: $DOCKER_VERSION)"
fi

# Check Docker Compose
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    error "Docker Compose is not installed!"
    info "Install Docker Compose from: https://docs.docker.com/compose/install/"
    exit 1
else
    if command -v docker compose &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
        success "Docker Compose is installed (version: $COMPOSE_VERSION)"
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_VERSION=$(docker-compose --version | cut -d ' ' -f3 | sed 's/,//')
        success "Docker Compose is installed (version: $COMPOSE_VERSION)"
        COMPOSE_CMD="docker-compose"
    fi
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    error "Docker daemon is not running!"
    info "Start Docker daemon and try again"
    exit 1
else
    success "Docker daemon is running"
fi

# ============================================
# Handle Status Check
# ============================================
if [ $CHECK_STATUS -eq 1 ]; then
    section "Services Status"
    $COMPOSE_CMD ps
    exit 0
fi

# ============================================
# Handle Stop
# ============================================
if [ $STOP_SERVICES -eq 1 ]; then
    section "Stopping Services"
    $COMPOSE_CMD down
    success "Services stopped"
    exit 0
fi

# ============================================
# Handle Restart
# ============================================
if [ $RESTART_SERVICES -eq 1 ]; then
    section "Restarting Services"
    $COMPOSE_CMD restart
    success "Services restarted"
    $COMPOSE_CMD ps
    exit 0
fi

# ============================================
# Setup Environment File
# ============================================
section "Setting up Environment Configuration"

if [ ! -f ".env" ]; then
    if [ ! -f ".env.example" ]; then
        error ".env.example file not found!"
        exit 1
    fi
    
    info "Creating .env file from .env.example..."
    cp .env.example .env
    success ".env file created"
    warning "Please edit .env file and set secure passwords!"
    info "Run: nano .env  (or use your preferred editor)"
else
    success ".env file already exists"
fi

# ============================================
# Create Necessary Directories
# ============================================
section "Creating Required Directories"

# Create backups directory
if [ ! -d "backups" ]; then
    mkdir -p backups
    success "Created backups directory"
else
    success "backups directory already exists"
fi

# Create .gitkeep in backups if it doesn't exist
if [ ! -f "backups/.gitkeep" ]; then
    touch backups/.gitkeep
    success "Created backups/.gitkeep"
fi

# ============================================
# Make Scripts Executable
# ============================================
section "Setting Script Permissions"

if [ -d "scripts" ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
    success "Scripts are executable"
fi

# ============================================
# Validate Environment Variables
# ============================================
section "Validating Environment Variables"

if [ -f "scripts/env-check.sh" ]; then
    if bash scripts/env-check.sh; then
        success "Environment validation passed"
    else
        error "Environment validation failed"
        warning "Please fix the issues above before starting services"
        if [ $VALIDATE_ONLY -eq 0 ] && [ $START_SERVICES -eq 0 ]; then
            info "You can edit .env and run validation again: ./init.sh --validate"
        fi
        exit 1
    fi
else
    warning "env-check.sh not found, skipping validation"
fi

# Exit if only validating
if [ $VALIDATE_ONLY -eq 1 ]; then
    success "Validation completed successfully!"
    exit 0
fi

# ============================================
# Docker Compose Configuration Check
# ============================================
section "Validating Docker Compose Configuration"

if $COMPOSE_CMD config --quiet; then
    success "docker-compose.yml is valid"
else
    error "docker-compose.yml has errors"
    exit 1
fi

# ============================================
# Start Services (if requested)
# ============================================
if [ $START_SERVICES -eq 1 ]; then
    section "Starting Services"
    
    # Check if services are already running
    RUNNING_CONTAINERS=$($COMPOSE_CMD ps -q 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
        info "Services are already running. Checking status..."
        $COMPOSE_CMD ps
        echo ""
        warning "To restart services, use: ./init.sh --restart"
        warning "To stop services first, use: ./init.sh --stop"
    else
        info "Pulling latest images..."
        $COMPOSE_CMD pull
        
        info "Starting services..."
        $COMPOSE_CMD up -d
        
        echo ""
        info "Waiting for services to be healthy..."
        sleep 5
        
        echo ""
        $COMPOSE_CMD ps
        
        echo ""
        success "Services started successfully!"
    fi
    
    section "Connection Information"
    echo "PostgreSQL Direct:   localhost:${POSTGRES_PORT:-5432}"
    echo "PgBouncer (Pooled):  localhost:${PGBOUNCER_PORT:-6432}"
    echo ""
    echo "Default credentials are in your .env file"
    
    section "Useful Commands"
    echo "List databases:      $COMPOSE_CMD --profile tools run --rm db_utils list-databases.sh"
    echo "Backup database:     $COMPOSE_CMD --profile tools run --rm db_utils backup.sh <db_name>"
    echo "Backup all:          $COMPOSE_CMD --profile tools run --rm db_utils backup-all.sh"
    echo "View logs:           $COMPOSE_CMD logs -f"
    echo "Stop services:       $COMPOSE_CMD down"
    echo "Check status:        ./init.sh --status"
else
    section "Initialization Complete"
    success "Environment is ready!"
    echo ""
    info "To start services, run:"
    echo "  ./init.sh --start"
    echo ""
    info "Or manually with:"
    echo "  $COMPOSE_CMD up -d"
fi

echo ""
