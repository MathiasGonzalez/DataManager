# Database Migrations

This directory contains database migration scripts that should be run in order after the initial database setup.

## Migration Naming Convention

Migrations should be named using the following pattern:
```
YYYYMMDD_HHMMSS_description.sql
```

Example:
```
20260130_120000_add_user_roles_table.sql
20260130_130000_add_audit_log_table.sql
```

## Running Migrations

### Using psql (Command Line)

```bash
docker-compose exec postgres psql -U datamanager -d datamanager_db -f /path/to/migration.sql
```

### Using Docker exec

```bash
docker-compose exec -T postgres psql -U datamanager datamanager_db < migrations/20260130_120000_migration.sql
```

### Using a Migration Tool

For production environments, consider using a migration tool like:
- [Flyway](https://flywaydb.org/)
- [Liquibase](https://www.liquibase.org/)
- [dbmate](https://github.com/amacneil/dbmate)
- Entity Framework Core Migrations (for .NET)

## Migration Best Practices

1. **Always test migrations** in a development environment first
2. **Make migrations reversible** by creating both `up` and `down` scripts
3. **Keep migrations small and focused** on a single change
4. **Version control all migrations** and never modify existing ones
5. **Document breaking changes** in the migration comments
6. **Create backups** before running migrations in production

## Example Migration Structure

### Up Migration (20260130_120000_add_user_roles.up.sql)
```sql
BEGIN;

CREATE TABLE IF NOT EXISTS datamanager.roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE datamanager.users ADD COLUMN role_id UUID REFERENCES datamanager.roles(id);

INSERT INTO datamanager.roles (name, description) VALUES
    ('admin', 'Administrator with full access'),
    ('user', 'Regular user with limited access');

COMMIT;
```

### Down Migration (20260130_120000_add_user_roles.down.sql)
```sql
BEGIN;

ALTER TABLE datamanager.users DROP COLUMN IF EXISTS role_id;
DROP TABLE IF EXISTS datamanager.roles;

COMMIT;
```

## Tracking Applied Migrations

Consider creating a migrations tracking table:

```sql
CREATE TABLE IF NOT EXISTS datamanager.schema_migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(255) UNIQUE NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
