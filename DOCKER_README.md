# DataManager - PostgreSQL Enterprise-Ready Environment

This repository provides a complete Docker Compose-based PostgreSQL database environment designed to simulate production conditions with connection pooling, administration tools, and automated backup/restore capabilities.

## 🏗️ Architecture

The environment consists of the following services:

- **PostgreSQL (Latest Alpine)**: Main database server with extensions support
- **PgBouncer**: Connection pooler for efficient database connection management
- **PgAdmin4**: Web-based database administration interface
- **db_utils**: Utility container for backup and restore operations

## 📋 Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher
- At least 2GB of available RAM
- 5GB of available disk space

## 🚀 Quick Start

### 1. Initial Setup

Clone the repository and create your environment configuration:

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your preferred credentials
nano .env  # or use your favorite editor
```

### 2. Start the Environment

```bash
# Start all services
docker compose up -d

# Check service status
docker compose ps

# View logs
docker compose logs -f
```

### 3. Access Services

Once all services are running:

- **PostgreSQL Direct Connection**: `localhost:5432`
- **PgBouncer (Pooled Connection)**: `localhost:6432`
- **PgAdmin Web Interface**: `http://localhost:5050`

## 🔧 Configuration

### Environment Variables

All configuration is managed through the `.env` file. Key variables include:

#### PostgreSQL Configuration
```env
POSTGRES_USER=postgres          # Database superuser
POSTGRES_PASSWORD=your_password # Secure password
POSTGRES_DB=datamanager        # Initial database name
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
PGADMIN_EMAIL=admin@datamanager.local  # Login email
PGADMIN_PASSWORD=admin                  # Login password
PGADMIN_PORT=5050                       # Web interface port
```

### Database Initialization

The `init-db.sql` script runs automatically on first startup and:

1. Enables common PostgreSQL extensions (`uuid-ossp`, `pg_stat_statements`)
2. Creates a sample application schema
3. Sets up initial tables (users, audit_logs)
4. Configures performance monitoring

You can customize this file to match your application's needs.

## 💾 Backup & Restore Operations

### Creating a Backup

Execute the backup script from the `db_utils` container:

```bash
# Create a timestamped backup
docker compose exec db_utils backup.sh
```

This will:
- Create a full database dump in `/backups` directory
- Compress the backup with gzip
- Name it with a timestamp (e.g., `datamanager_backup_20240101_120000.sql.gz`)
- Automatically clean up backups older than 7 days

### Restoring from Backup

To restore from a specific backup file:

```bash
# List available backups
docker compose exec db_utils ls -lh /backups

# Restore from a specific backup
docker compose exec db_utils restore.sh /backups/datamanager_backup_20240101_120000.sql.gz
```

⚠️ **Warning**: Restore operations will replace all current data in the database!

### Manual Backup/Restore Commands

You can also perform manual operations:

```bash
# Manual backup (uncompressed)
docker compose exec postgres pg_dump -U postgres datamanager > backup.sql

# Manual restore
docker compose exec -T postgres psql -U postgres datamanager < backup.sql

# Backup with custom format (for large databases)
docker compose exec postgres pg_dump -U postgres -Fc datamanager > backup.dump
```

## 🔌 Connecting to the Database

### Using PgBouncer (Recommended for Applications)

Connection pooling improves performance for applications with many connections:

```bash
# Connection string
postgresql://postgres:your_password@localhost:6432/datamanager

# Using psql
psql -h localhost -p 6432 -U postgres -d datamanager
```

### Direct PostgreSQL Connection

For administrative tasks or when pooling is not needed:

```bash
# Connection string
postgresql://postgres:your_password@localhost:5432/datamanager

# Using psql
psql -h localhost -p 5432 -U postgres -d datamanager

# From within the postgres container
docker compose exec postgres psql -U postgres -d datamanager
```

## 🖥️ Using PgAdmin

1. Open your browser and navigate to `http://localhost:5050`
2. Login with credentials from your `.env` file
3. Add a new server:
   - **General > Name**: DataManager
   - **Connection > Host**: `postgres` (service name)
   - **Connection > Port**: `5432`
   - **Connection > Username**: Your `POSTGRES_USER`
   - **Connection > Password**: Your `POSTGRES_PASSWORD`

## 📊 Monitoring & Performance

### Check Database Status

```bash
# View active connections
docker compose exec postgres psql -U postgres -d datamanager -c "SELECT * FROM pg_stat_activity;"

# View database size
docker compose exec postgres psql -U postgres -c "\l+"

# Check query statistics (requires pg_stat_statements extension)
docker compose exec postgres psql -U postgres -d datamanager -c "SELECT * FROM pg_stat_statements LIMIT 10;"
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

## 🔒 Security Best Practices

1. **Change default passwords**: Update all passwords in `.env` before deploying
2. **Use strong passwords**: Generate complex passwords for production
3. **Limit network exposure**: Consider using internal networks only
4. **Regular backups**: Schedule automated backups using cron or similar
5. **Keep images updated**: Regularly pull and deploy updated images
6. **Review logs**: Monitor logs for suspicious activity

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
