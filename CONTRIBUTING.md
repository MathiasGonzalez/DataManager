# Contributing to DataManager

Thank you for your interest in contributing to DataManager! This document provides guidelines for setting up the development environment and contributing to the project.

## Development Setup

### Prerequisites

Before you begin, ensure you have the following installed:
- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- Git
- Your preferred IDE or text editor

### Setting Up the Development Environment

1. **Fork and clone the repository**

   ```bash
   git clone https://github.com/YOUR_USERNAME/DataManager.git
   cd DataManager
   ```

2. **Set up environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your preferred development settings.

3. **Start the database**

   ```bash
   docker compose up -d
   ```

   Or using Make:
   ```bash
   make up
   ```

4. **Verify the setup**

   ```bash
   ./health-check.sh
   ```

   Or using Make:
   ```bash
   make ps
   ```

## Database Development

### Working with the Database

- **Connect via psql**: `make psql` or `docker compose exec postgres psql -U datamanager -d datamanager_db`
- **View logs**: `make logs-postgres`
- **Create backup**: `make backup`
- **Restore backup**: `make restore`

### Adding New Tables or Schemas

1. Create a new SQL file in `init-scripts/` for initial setup (e.g., `init-scripts/02-new-tables.sql`)
2. For existing databases, create a migration in `migrations/` directory
3. Test your changes by rebuilding the database:
   ```bash
   docker compose down -v
   docker compose up -d
   ```

### Database Schema Changes

Follow these guidelines when modifying the database schema:

1. **Create migrations**: Always create migration scripts for schema changes
2. **Test locally**: Test all changes in your local development environment
3. **Document changes**: Update relevant documentation
4. **Backward compatibility**: Ensure changes don't break existing functionality
5. **Data migrations**: Include data migration scripts when changing data structures

## Code Style and Standards

### SQL Guidelines

- Use `snake_case` for table and column names
- Include comments for complex queries
- Use transactions for multi-statement operations
- Add indexes for frequently queried columns
- Use UUIDs for primary keys (using `uuid_generate_v4()`)

Example:
```sql
-- Good
CREATE TABLE datamanager.my_table (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_my_table_user_name ON datamanager.my_table(user_name);
```

### Docker Compose Guidelines

- Keep services isolated
- Use health checks for dependent services
- Define resource limits for production services
- Use named volumes for persistent data
- Document all environment variables

## Testing

### Testing Database Changes

1. **Reset the database**: `docker compose down -v && docker compose up -d`
2. **Run initialization scripts**: Automatically executed on container creation
3. **Verify schema**: Check tables, indexes, and constraints
4. **Test queries**: Ensure performance is acceptable
5. **Run health check**: `./health-check.sh`

### Manual Testing

Before submitting a pull request:
- Verify all containers start successfully
- Test database connections
- Verify data persistence across container restarts
- Check logs for errors or warnings
- Test backup and restore procedures

## Submitting Changes

### Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the coding standards
   - Test your changes thoroughly
   - Update documentation as needed

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: brief description of changes"
   ```

   Commit message format:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for modifications
   - `Docs:` for documentation changes

4. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Include screenshots for UI changes
   - List any breaking changes

### Pull Request Checklist

- [ ] Code follows the project's style guidelines
- [ ] Database changes are tested and documented
- [ ] Documentation has been updated
- [ ] All containers start successfully
- [ ] Health check passes
- [ ] No sensitive data (passwords, keys) in commits
- [ ] `.env.example` is updated if new variables are added

## Getting Help

If you need help or have questions:
- Open an issue for bugs or feature requests
- Check existing issues and pull requests
- Review the README.md for setup instructions

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow best practices and standards

## License

By contributing to DataManager, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

Thank you for contributing to DataManager!
