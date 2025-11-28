# Environment Variables Setup Guide

## Quick Start

1. **Create `.env` file from example:**
   ```bash
   cp .env.example .env
   ```

2. **Generate secure secrets:**
   ```bash
   # Generate JWT secret (32+ characters)
   openssl rand -base64 32
   
   # Generate database password (24+ characters)
   openssl rand -base64 24
   
   # Generate REST API password (16+ characters)
   openssl rand -base64 16
   ```

3. **Edit `.env` file** with your generated secrets

4. **Set proper file permissions:**
   ```bash
   chmod 600 .env
   ```

## Environment Variables Reference

### Database Configuration
- `DB_HOST` - Database hostname (default: `elite-quiz-admin-db`)
- `DB_USER` - Database username (default: `root`)
- `DB_PASSWORD` - **REQUIRED** - Database password (no default for security)
- `DB_NAME` - Database name (default: `elite_quiz_237`)
- `DB_PORT` - Database port (default: `3306`)

### JWT Configuration
- `JWT_SECRET_KEY` - **REQUIRED** - Secret key for JWT token signing (minimum 32 characters)
  - Generate with: `openssl rand -base64 32`

### REST API Configuration
- `REST_API_USERNAME` - REST API username (default: `admin`)
- `REST_API_PASSWORD` - **REQUIRED** - REST API password (no default for security)
  - Generate with: `openssl rand -base64 16`

### Application Environment
- `CI_ENV` - Application environment: `development`, `testing`, or `production`
  - Default: `development`

### Docker Configuration (Optional)
- `APP_PORT` - Web server port (default: `8080`)
- `DB_PORT` - Database port (default: `3310`)
- `PHPMYADMIN_PORT` - phpMyAdmin port (default: `8090`)

## Docker Setup

When using Docker Compose, environment variables are automatically passed to containers:

```bash
# Start services with environment variables
docker-compose up -d
```

Make sure your `.env` file is in the project root (same directory as `docker-compose.yml`).

## Local Development (Without Docker)

For local development without Docker:

1. Create `.env` file in project root
2. The application will automatically load it via `env_helper.php`
3. Environment variables take precedence over `.env` file values

## Security Notes

⚠️ **IMPORTANT:**
- **NEVER** commit `.env` file to version control
- **ALWAYS** use strong, unique passwords
- **ROTATE** secrets regularly (every 90 days)
- **RESTRICT** file permissions: `chmod 600 .env`

## Verification

After setup, verify your configuration:

1. **Check database connection:**
   - Access admin panel
   - Verify you can log in

2. **Check JWT tokens:**
   - Test API authentication
   - Verify tokens are generated correctly

3. **Check REST API:**
   - Test REST API endpoints
   - Verify authentication works

## Troubleshooting

### Environment variables not loading

1. Check `.env` file exists in project root
2. Verify file permissions: `ls -la .env`
3. Check file syntax (no spaces around `=`)
4. Restart web server/Docker containers

### Database connection fails

1. Verify `DB_PASSWORD` is set correctly
2. Check database is running
3. Verify network connectivity
4. Check database user permissions

### JWT tokens not working

1. Verify `JWT_SECRET_KEY` is set (minimum 32 characters)
2. Check for special characters in secret (may need quotes)
3. Restart application after changing JWT secret

## Migration from Hardcoded Values

If you're migrating from hardcoded values:

1. **Backup current configuration**
2. **Create `.env` file** with current values
3. **Update code** to use environment variables (already done)
4. **Test thoroughly** before deploying
5. **Rotate all secrets** after migration

---

For more information, see `SECURITY_CHECKLIST.md`

