.PHONY: help up down restart logs logs-postgres logs-pgadmin ps backup restore clean

# Default target
help:
	@echo "DataManager - Docker PostgreSQL Management"
	@echo ""
	@echo "Available targets:"
	@echo "  make up           - Start all services"
	@echo "  make down         - Stop all services"
	@echo "  make restart      - Restart all services"
	@echo "  make logs         - View logs from all services"
	@echo "  make logs-postgres - View PostgreSQL logs"
	@echo "  make logs-pgadmin - View pgAdmin logs"
	@echo "  make ps           - Show running containers"
	@echo "  make backup       - Create database backup"
	@echo "  make restore      - Restore database from backup.sql"
	@echo "  make clean        - Stop services and remove volumes (⚠️  deletes data)"
	@echo "  make psql         - Connect to database with psql"
	@echo "  make init         - Initialize environment from .env.example"

# Initialize environment
init:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✓ Created .env file from .env.example"; \
		echo "⚠  Please review and update the .env file with your settings"; \
	else \
		echo "✓ .env file already exists"; \
	fi

# Start services
up: init
	@echo "Starting services..."
	docker compose up -d
	@echo "✓ Services started"
	@echo "  PostgreSQL: localhost:5432"
	@echo "  pgAdmin: http://localhost:5050"

# Stop services
down:
	@echo "Stopping services..."
	docker compose down
	@echo "✓ Services stopped"

# Restart services
restart:
	@echo "Restarting services..."
	docker compose restart
	@echo "✓ Services restarted"

# View all logs
logs:
	docker compose logs -f

# View PostgreSQL logs
logs-postgres:
	docker compose logs -f postgres

# View pgAdmin logs
logs-pgadmin:
	docker compose logs -f pgadmin

# Show running containers
ps:
	docker compose ps

# Create backup
backup:
	@echo "Creating database backup..."
	@docker compose exec postgres pg_dump -U datamanager datamanager_db > backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✓ Backup created: backup_$$(date +%Y%m%d_%H%M%S).sql"

# Restore from backup
restore:
	@if [ ! -f backup.sql ]; then \
		echo "⚠  Error: backup.sql not found"; \
		exit 1; \
	fi
	@echo "Restoring database from backup.sql..."
	@docker compose exec -T postgres psql -U datamanager datamanager_db < backup.sql
	@echo "✓ Database restored"

# Clean everything (including volumes)
clean:
	@echo "⚠  WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✓ Services stopped and volumes removed"; \
	else \
		echo "Cancelled"; \
	fi

# Connect to database with psql
psql:
	docker compose exec postgres psql -U datamanager -d datamanager_db
