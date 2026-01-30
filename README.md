# DataManager

A data management application with PostgreSQL database running in Docker.

## Prerequisites

- [Docker](https://www.docker.com/get-started) (version 20.10 or higher)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0 or higher)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/MathiasGonzalez/DataManager.git
cd DataManager
```

### 2. Configure Environment Variables

Copy the example environment file and customize it if needed:

```bash
cp .env.example .env
```

Edit the `.env` file to set your preferred database credentials and ports.

### 3. Start the Database

Start the PostgreSQL database and pgAdmin using Docker Compose:

```bash
docker compose up -d
```

This command will:
- Pull the PostgreSQL 16 Alpine image
- Create a PostgreSQL container with the configured database
- Run initialization scripts from `init-scripts/` directory
- Start pgAdmin for database management
- Create persistent volumes for data storage

### 4. Verify the Setup

Check if the containers are running:

```bash
docker compose ps
```

You should see two containers running:
- `datamanager-postgres` - PostgreSQL database server
- `datamanager-pgadmin` - pgAdmin web interface

### 5. Access the Database

#### Using psql (Command Line)

Connect to the database using psql:

```bash
docker compose exec postgres psql -U datamanager -d datamanager_db
```

#### Using pgAdmin (Web Interface)

1. Open your browser and navigate to: `http://localhost:5050`
2. Login with the credentials from your `.env` file:
   - Email: `admin@datamanager.com` (default)
   - Password: `admin` (default)
3. Add a new server with these connection details:
   - Host: `postgres` (container name)
   - Port: `5432`
   - Database: `datamanager_db`
   - Username: `datamanager`
   - Password: `datamanager_password`

#### Connection String

Use this connection string in your application:

```
postgresql://datamanager:datamanager_password@localhost:5432/datamanager_db
```

Or use the `DATABASE_URL` variable from your `.env` file.

## Database Schema

The initialization script creates:

- **Schema**: `datamanager`
- **Extensions**: `uuid-ossp`, `pgcrypto`
- **Tables**:
  - `users` - User information
  - `data_entries` - Data records with metadata
- **Triggers**: Automatic `updated_at` timestamp updates
- **Sample Data**: Two test users for development

## Docker Commands

### Start the services
```bash
docker compose up -d
```

### Stop the services
```bash
docker compose down
```

### Stop and remove volumes (⚠️ This will delete all data)
```bash
docker compose down -v
```

### View logs
```bash
# All services
docker compose logs -f

# PostgreSQL only
docker compose logs -f postgres

# pgAdmin only
docker compose logs -f pgadmin
```

### Restart services
```bash
docker compose restart
```

### Execute SQL directly
```bash
docker compose exec postgres psql -U datamanager -d datamanager_db -c "SELECT * FROM datamanager.users;"
```

## Database Backup and Restore

### Backup

Create a backup of your database:

```bash
docker compose exec postgres pg_dump -U datamanager datamanager_db > backup.sql
```

Or with compression:

```bash
docker compose exec postgres pg_dump -U datamanager datamanager_db | gzip > backup.sql.gz
```

### Restore

Restore from a backup:

```bash
docker compose exec -T postgres psql -U datamanager datamanager_db < backup.sql
```

Or from compressed backup:

```bash
gunzip -c backup.sql.gz | docker compose exec -T postgres psql -U datamanager datamanager_db
```

## Customization

### Adding Custom Initialization Scripts

Add SQL files to the `init-scripts/` directory. Files are executed in alphabetical order during the first container startup.

Example:
```bash
# Create a new initialization script
echo "CREATE TABLE my_table (id SERIAL PRIMARY KEY, name VARCHAR(100));" > init-scripts/02-custom-tables.sql

# Rebuild to apply changes
docker compose down -v
docker compose up -d
```

### Changing Database Configuration

Modify the `.env` file and restart the containers:

```bash
docker compose down
docker compose up -d
```

## Troubleshooting

### Container won't start

Check the logs:
```bash
docker compose logs postgres
```

### Can't connect to database

1. Verify the container is running: `docker compose ps`
2. Check the port is not in use: `netstat -an | grep 5432`
3. Verify credentials in `.env` file

### Permission denied errors

Reset the volumes:
```bash
docker compose down -v
docker compose up -d
```

### Database won't initialize

Check initialization script logs:
```bash
docker compose logs postgres | grep -A 10 "database system is ready"
```

## Production Considerations

For production deployments:

1. **Change default passwords** in `.env` file
2. **Use secrets management** instead of `.env` files
3. **Configure backups** with a automated backup strategy
4. **Monitor database performance** using tools like pg_stat_statements
5. **Set up replication** for high availability
6. **Use SSL/TLS** for encrypted connections
7. **Restrict network access** using firewalls and security groups
8. **Regular security updates** of Docker images

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)

## License

See [LICENSE](LICENSE) file for details.