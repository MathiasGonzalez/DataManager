# PostgreSQL Multi-Project Server - Enterprise-Ready Environment

This repository provides a complete Docker Compose-based PostgreSQL database server designed for hosting multiple project databases on a VPS. It includes connection pooling, administration tools, and automated backup/restore capabilities for managing multiple databases efficiently.

## 🏗️ Architecture

The environment consists of the following services:

- **PostgreSQL 18.1 (Alpine)**: Main database server with common extensions enabled
- **PgBouncer**: Connection pooler for efficient database connection management across all databases
- **PgAdmin4**: Web-based database administration interface for all databases
- **db_utils**: Utility container for backup, restore, and database management operations

### Resource Limits

All services have resource limits configured for optimal performance and resource management:

- **PostgreSQL**: 2 CPUs / 2GB RAM (limit), 1 CPU / 1GB RAM (reserved)
- **PgBouncer**: 0.5 CPUs / 512MB RAM (limit), 0.25 CPUs / 256MB RAM (reserved)
- **PgAdmin**: 0.5 CPUs / 512MB RAM (limit), 0.25 CPUs / 256MB RAM (reserved)
- **db_utils**: 0.5 CPUs / 256MB RAM (limit), 0.1 CPUs / 128MB RAM (reserved)

## 📋 Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher
- At least 2GB of available RAM
- 5GB+ of available disk space (depending on database sizes)
- (For VPS deployment) Properly configured firewall

## 🚀 Quick Start

### Method 1: Using the Initialization Script (Recommended)

The easiest way to get started is using the automated initialization script:

```bash
# Initialize environment (creates .env, validates configuration)
./init.sh

# Edit the .env file with secure passwords
nano .env

# Validate your configuration
./init.sh --validate

# Start all services
./init.sh --start

# Check services status
./init.sh --status
```

### Method 2: Manual Setup

If you prefer manual setup:

```bash
# 1. Copy the example environment file
cp .env.example .env

# 2. IMPORTANT: Edit .env and change default passwords!
nano .env  # or use your favorite editor

# 3. Validate environment variables
./scripts/env-check.sh

# 4. Start all services
docker compose up -d

# 5. Check service status
docker compose ps
```

### Important: Environment Validation

**Always validate your environment before starting services:**

```bash
# Validate configuration
./scripts/env-check.sh

# Strict mode (fails on warnings)
./scripts/env-check.sh --strict
```

The validation script checks:
- ✓ Required environment variables are set
- ✓ Passwords are not using default/weak values
- ✓ Port conflicts
- ✓ Security configurations

Once all services are running:

- **PostgreSQL Direct Connection**: `localhost:5432`
- **PgBouncer (Pooled Connection)**: `localhost:6432`
- **PgAdmin Web Interface**: `http://localhost:5050`

## 🛠️ Initialization Script Features

The `init.sh` script provides idempotent initialization and management:

### Available Commands

```bash
./init.sh              # Initialize only (create .env, validate, setup dirs)
./init.sh --start      # Initialize and start services
./init.sh --stop       # Stop all services
./init.sh --restart    # Restart all services
./init.sh --status     # Check services status
./init.sh --validate   # Validate environment only
./init.sh --help       # Show help message
```

### What the Initialization Does

1. **Checks Prerequisites**: Verifies Docker and Docker Compose are installed
2. **Creates .env File**: Copies from .env.example if not exists
3. **Validates Environment**: Runs comprehensive validation checks
4. **Creates Directories**: Sets up required directories (backups, etc.)
5. **Sets Permissions**: Makes all scripts executable
6. **Optionally Starts Services**: With `--start` flag

### Idempotent Operations

All operations are designed to be idempotent (safe to run multiple times):

- **Start (`--start`)**: Checks if services are already running before attempting to start
- **Stop (`--stop`)**: Uses `docker compose down` which preserves volumes (data is kept)
- **Restart (`--restart`)**: Gracefully restarts all running services
- **Status (`--status`)**: Always safe to check current state

**Important**: 
- Stopping services (`./init.sh --stop`) preserves all data in volumes
- Restarting services maintains all database data and configurations
- Starting already-running services shows current status without changes

### Environment Validation

The `env-check.sh` script validates:

- ✅ All required environment variables are set
- ✅ Passwords are secure (not defaults/placeholders)
- ✅ Password strength (minimum length)
- ✅ No port conflicts between services
- ✅ Security configurations

```bash
# Run validation independently
./scripts/env-check.sh

# Strict mode (exit on warnings)
./scripts/env-check.sh --strict
```

## 🗄️ Multi-Database Management

This setup is designed to host multiple project databases on a single PostgreSQL server.

### Creating a New Database for a Project

```bash
# Method 1: Using psql
docker compose exec db_utils psql -h postgres -U postgres -c "CREATE DATABASE myproject_db;"

# Method 2: Using PgAdmin web interface
# 1. Open http://localhost:5050
# 2. Right-click on "Databases" → "Create" → "Database"
# 3. Enter database name and save
```

### Listing All Databases

```bash
# List all databases with sizes and connection info
docker compose exec db_utils list-databases.sh
```

### Connecting to a Specific Database

```bash
# Connect via psql
docker compose exec db_utils psql -h postgres -U postgres -d myproject_db

# Connection string for applications
******localhost:5432/myproject_db
# Or via PgBouncer (pooled):
******localhost:6432/myproject_db
```

### Managing Project Database Users

```bash
# Create a dedicated user for a project
docker compose exec db_utils psql -h postgres -U postgres << EOF
CREATE USER myproject_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE myproject_db TO myproject_user;
\c myproject_db
GRANT ALL ON SCHEMA public TO myproject_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO myproject_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO myproject_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO myproject_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO myproject_user;
EOF
```

## 🔧 Configuration

### Environment Variables

All configuration is managed through the `.env` file. Key variables include:

#### PostgreSQL Configuration
```env
POSTGRES_USER=postgres          # Database superuser
POSTGRES_PASSWORD=CHANGE_THIS   # IMPORTANT: Set a strong password!
POSTGRES_DB=postgres            # System database (don't change)
POSTGRES_PORT=5432             # Host port mapping
```

#### PgBouncer Configuration
```env
PGBOUNCER_PORT=6432                    # Pooler port
PGBOUNCER_MAX_CLIENT_CONN=100          # Max client connections
PGBOUNCER_DEFAULT_POOL_SIZE=25         # Default pool size
PGBOUNCER_MIN_POOL_SIZE=10             # Minimum pool size
PGBOUNCER_RESERVE_POOL_SIZE=5          # Reserve pool size
PGBOUNCER_SERVER_IDLE_TIMEOUT=600      # Idle timeout (seconds)
PGBOUNCER_MAX_DB_CONNECTIONS=50        # Max database connections
```

#### PgAdmin Configuration
```env
PGADMIN_EMAIL=admin@example.com        # Login email
PGADMIN_PASSWORD=admin                  # Login password (change in production!)
PGADMIN_PORT=5050                       # Web interface port
```

### Database Initialization

The `init-db.sql` script runs automatically on first startup and:

1. Enables common PostgreSQL extensions in template1 (`uuid-ossp`, `pg_stat_statements`, `pg_trgm`, `btree_gist`, `hstore`)
2. Configures performance settings optimized for multi-database usage
3. All extensions are automatically available for new databases created after initialization

**Note**: This script does NOT create project-specific databases or schemas. You create those as needed for each project.

## 💾 Backup & Restore Operations

### Backing Up a Specific Database

```bash
# Backup a single database
docker compose exec db_utils backup.sh myproject_db

# This creates: /backups/myproject_db_backup_YYYYMMDD_HHMMSS.sql.gz
```

### Backing Up All Databases

```bash
# Backup all user databases at once
docker compose exec db_utils backup-all.sh

# This creates separate backups for each database
```

### Restoring from Backup

```bash
# List available backups
docker compose exec db_utils ls -lh /backups

# Restore to original database (extracted from filename)
docker compose exec db_utils restore.sh /backups/myproject_db_backup_20240101_120000.sql.gz

# Restore to a different database
docker compose exec db_utils restore.sh /backups/myproject_db_backup_20240101_120000.sql.gz new_database_name
```

⚠️ **Warning**: Restore operations will replace all current data in the target database!

### Automated Backup Schedule

For production VPS deployment, set up automated backups using cron:

```bash
# Add to crontab (crontab -e)
# Backup all databases daily at 2 AM
0 2 * * * cd /path/to/repo && docker compose exec -T db_utils backup-all.sh >> /var/log/postgres-backup.log 2>&1

# Backup specific critical database every 6 hours
0 */6 * * * cd /path/to/repo && docker compose exec -T db_utils backup.sh critical_db >> /var/log/postgres-backup.log 2>&1
```
```

## 🔌 Connecting to Databases

### From Your Applications (Recommended: Use PgBouncer)

Connection pooling improves performance for applications with many concurrent connections:

```bash
# Connection string format
postgresql://username:password@host:6432/database_name

# Example with default superuser
postgresql://postgres:your_password@localhost:6432/myproject_db

# Example with project-specific user
postgresql://myproject_user:project_password@localhost:6432/myproject_db
```

### Direct PostgreSQL Connection

For administrative tasks or when pooling is not needed:

```bash
# Connection string format
postgresql://postgres:your_password@localhost:5432/database_name

# Using psql
psql -h localhost -p 5432 -U postgres -d myproject_db

# From within the db_utils container
docker compose exec db_utils psql -h postgres -U postgres -d myproject_db
```

### From Remote Servers/VPS

When running on a VPS and connecting from other servers:

```bash
# Replace localhost with your VPS IP or domain
postgresql://postgres:password@your-vps-ip:5432/database_name

# Via PgBouncer (recommended)
postgresql://postgres:password@your-vps-ip:6432/database_name
```

## 🖥️ Using PgAdmin

1. Open your browser and navigate to `http://localhost:5050` (or `http://your-vps-ip:5050`)
2. Login with credentials from your `.env` file
3. Add a new server connection:
   - **General > Name**: PostgreSQL Server (or any name you prefer)
   - **Connection > Host**: `postgres` (when PgAdmin is in same Docker network) or your VPS IP
   - **Connection > Port**: `5432`
   - **Connection > Maintenance Database**: `postgres`
   - **Connection > Username**: Your `POSTGRES_USER`
   - **Connection > Password**: Your `POSTGRES_PASSWORD`
   - **Save password**: ✓ (optional, for convenience)

Now you can see and manage all databases on the server from PgAdmin.

## 📊 Monitoring & Performance

### Check All Databases Status

```bash
# List all databases with sizes and connections
docker compose exec db_utils list-databases.sh

# View active connections across all databases
docker compose exec db_utils psql -h postgres -U postgres -c "SELECT datname, count(*) as connections FROM pg_stat_activity GROUP BY datname;"

# View all database sizes
docker compose exec db_utils psql -h postgres -U postgres -c "\l+"

# Check query statistics for a specific database
docker compose exec db_utils psql -h postgres -U postgres -d myproject_db -c "SELECT * FROM pg_stat_statements LIMIT 10;"
```

### Performance Monitoring

```bash
# Check slow queries across all databases
docker compose exec db_utils psql -h postgres -U postgres << EOF
SELECT 
    datname,
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
JOIN pg_database ON pg_stat_statements.dbid = pg_database.oid
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 20;
EOF

# Monitor database sizes over time
docker compose exec db_utils psql -h postgres -U postgres -c "
SELECT 
    datname AS database,
    pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;
"
```

### PgBouncer Statistics

```bash
# Connect to PgBouncer admin console
docker compose exec pgbouncer psql -p 5432 -U postgres pgbouncer

# View pool statistics
SHOW POOLS;

# View client statistics
SHOW CLIENTS;

# View server statistics
SHOW SERVERS;
```

## 🛠️ Maintenance Commands

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (⚠️ deletes all data)
docker compose down -v
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart postgres
```

### View Logs

```bash
# View all logs
docker compose logs -f

# View logs for specific service
docker compose logs -f postgres
docker compose logs -f pgbouncer
docker compose logs -f pgadmin
```

### Update Services

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d --force-recreate
```

## 🔒 Security Best Practices for VPS Deployment

### Essential Security Measures

1. **Change ALL default passwords**: 
   ```bash
   # Generate strong passwords
   openssl rand -base64 32
   
   # Update .env file with strong passwords
   POSTGRES_PASSWORD=<generated-strong-password>
   PGADMIN_PASSWORD=<another-strong-password>
   ```

2. **Firewall Configuration**:
   ```bash
   # Only allow connections from specific IPs (example with ufw)
   sudo ufw allow from YOUR_APP_SERVER_IP to any port 5432
   sudo ufw allow from YOUR_APP_SERVER_IP to any port 6432
   
   # Or allow only within VPS local network
   sudo ufw allow from 10.0.0.0/8 to any port 5432
   
   # Allow PgAdmin only from your IP
   sudo ufw allow from YOUR_ADMIN_IP to any port 5050
   ```

3. **Use SSL/TLS for connections**:
   ```bash
   # For production, configure PostgreSQL with SSL certificates
   # Add to docker-compose.yml postgres environment:
   POSTGRES_SSL: "on"
   
   # Mount SSL certificates
   volumes:
     - ./certs/server.crt:/var/lib/postgresql/server.crt:ro
     - ./certs/server.key:/var/lib/postgresql/server.key:ro
   ```

4. **Create project-specific database users** (never use superuser for applications):
   ```bash
   # Each project should have its own user with limited privileges
   docker compose exec db_utils psql -h postgres -U postgres << EOF
   CREATE USER project1_user WITH PASSWORD 'strong_password_here';
   GRANT CONNECT ON DATABASE project1_db TO project1_user;
   \c project1_db
   GRANT ALL ON SCHEMA public TO project1_user;
   GRANT ALL ON ALL TABLES IN SCHEMA public TO project1_user;
   EOF
   ```

5. **Regular security updates**:
   ```bash
   # Keep Docker images updated
   docker compose pull
   docker compose up -d --force-recreate
   
   # Update host system regularly
   sudo apt update && sudo apt upgrade
   ```

6. **Backup encryption**: Encrypt sensitive backups before storing offsite
   ```bash
   # Encrypt backup
   gpg --symmetric --cipher-algo AES256 /backups/sensitive_db_backup.sql.gz
   
   # Decrypt when needed
   gpg --decrypt /backups/sensitive_db_backup.sql.gz.gpg > /backups/sensitive_db_backup.sql.gz
   ```

7. **Network isolation**: Consider using Docker networks to isolate database from internet
   ```bash
   # Don't expose PostgreSQL port to internet
   # Instead, use VPN or SSH tunnel for remote access
   ssh -L 5432:localhost:5432 user@your-vps-ip
   ```

8. **Monitor access logs**:
   ```bash
   # Enable and monitor PostgreSQL logs
   docker compose logs postgres | grep -i "connection\|authentication\|error"
   ```

9. **Limit PgAdmin exposure**:
   ```bash
   # Option 1: Use reverse proxy with authentication
   # Option 2: Only expose on localhost and use SSH tunnel
   # In docker-compose.yml, change:
   ports:
     - "127.0.0.1:5050:80"  # Only accessible from localhost
   ```

10. **Database connection limits**:
    ```bash
    # Set per-database connection limits to prevent resource exhaustion
    docker compose exec db_utils psql -h postgres -U postgres -c "
    ALTER DATABASE myproject_db CONNECTION LIMIT 50;
    "
    ```

### VPS-Specific Configuration

**Resource Limits**: Configure Docker resource limits in docker-compose.yml:
```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

**Data Persistence**: Ensure backups are stored outside the Docker host:
```bash
# Sync backups to remote storage
rsync -avz /path/to/backups/ user@backup-server:/backups/
# Or use cloud storage (S3, etc.)
aws s3 sync /path/to/backups/ s3://your-bucket/postgres-backups/
```

## 🐛 Troubleshooting

### Services won't start

```bash
# Check service status and errors
docker compose ps
docker compose logs

# Ensure ports are not in use
sudo lsof -i :5432
sudo lsof -i :6432
sudo lsof -i :5050
```

### Cannot connect to database

1. Verify services are running: `docker compose ps`
2. Check network connectivity: `docker compose exec db_utils ping postgres`
3. Verify credentials in `.env` file
4. Review PostgreSQL logs: `docker compose logs postgres`

### PgAdmin cannot connect to PostgreSQL

- Use hostname `postgres` (not `localhost`) when configuring the server
- Ensure credentials match those in `.env`
- Verify PostgreSQL service is healthy: `docker compose ps postgres`

### Backup/Restore fails

1. Check disk space: `df -h`
2. Verify backup directory permissions
3. Review db_utils logs: `docker compose logs db_utils`

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PgBouncer Documentation](https://www.pgbouncer.org/usage.html)
- [PgAdmin Documentation](https://www.pgadmin.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 📝 License

This project is provided as-is for development and testing purposes.

## 🤝 Contributing

Feel free to open issues or submit pull requests with improvements!
