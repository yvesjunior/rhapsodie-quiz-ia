# Rhapsody Quiz Admin Panel

A comprehensive admin panel for managing the Rhapsody Quiz application, built with CodeIgniter and Docker.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Common Commands](#common-commands)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git** (for cloning the repository)

Verify your installation:
```bash
docker --version
docker-compose --version
```

---

## Quick Start

```bash
# Run the automated setup script
./start-panel.sh
```

This script will:
1. Check/create `.env` file with secure secrets
2. Start Docker containers
3. Update database password if needed
4. Verify everything is working

**Access the Application:**
- **Admin Panel:** http://localhost:8080
- **phpMyAdmin:** http://localhost:8090
- **Database:** localhost:3310

---

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd "Rhapsody Quiz - Admin Panel - v2.3.7"
```

### 2. Create Environment File

**Option A: Use the automated script (Recommended)**
```bash
./scripts/generate-secrets.sh
# Answer 'y' when prompted to create/update .env file
chmod 600 .env
```

**Option B: Create manually**
```bash
cp .env.example .env
nano .env  # Fill in your secrets
chmod 600 .env
```

### 3. Start Services

```bash
# Start all containers
docker-compose up -d

# Wait for database to initialize (15 seconds)
sleep 15

# Update database password if using existing database
DB_PASS=$(grep "^DB_PASSWORD=" .env | cut -d '=' -f2)
docker exec elite-quiz-admin-db mysql -uroot -prootpassword -e "ALTER USER 'root'@'%' IDENTIFIED BY '$DB_PASS'; ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;" 2>/dev/null

# Restart web container
docker-compose restart web

# Verify containers are running
docker-compose ps
```

---

## Configuration

### Environment Variables

The application uses environment variables for all sensitive configuration. Key variables:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DB_HOST` | Database hostname | No | `elite-quiz-admin-db` |
| `DB_USER` | Database username | No | `root` |
| `DB_PASSWORD` | Database password | **Yes** | - |
| `DB_NAME` | Database name | No | `elite_quiz_237` |
| `JWT_SECRET_KEY` | JWT token signing key | **Yes** | - |
| `REST_API_USERNAME` | REST API username | No | `admin` |
| `REST_API_PASSWORD` | REST API password | **Yes** | - |
| `CI_ENV` | Application environment | No | `development` |
| `APP_PORT` | Web server port | No | `8080` |
| `DB_PORT` | Database port | No | `3310` |
| `PHPMYADMIN_PORT` | phpMyAdmin port | No | `8090` |

### Generating Secure Secrets

```bash
# JWT Secret (32+ characters)
openssl rand -base64 32

# Database Password (24+ characters)
openssl rand -base64 24

# REST API Password (16+ characters)
openssl rand -base64 16
```

### File Permissions

Always set secure permissions on `.env`:
```bash
chmod 600 .env
```

---

## Common Commands

### Container Management

| Task | Command |
|------|---------|
| Start services | `docker-compose up -d` |
| Stop services | `docker-compose down` |
| Restart services | `docker-compose restart` |
| View logs | `docker-compose logs -f` |
| Check status | `docker-compose ps` |
| Rebuild containers | `docker-compose up -d --build` |

### Database Operations

```bash
# Connect to MySQL
docker exec -it elite-quiz-admin-db mysql -uroot -p

# Run SQL command
docker exec elite-quiz-admin-db mysql -uroot -p"$DB_PASSWORD" -e "SHOW DATABASES;"

# Backup database
docker exec elite-quiz-admin-db mysqldump -uroot -p"$DB_PASSWORD" elite_quiz_237 > backup.sql

# Restore database
docker exec -i elite-quiz-admin-db mysql -uroot -p"$DB_PASSWORD" elite_quiz_237 < backup.sql
```

### Environment Variables

```bash
# Check environment variables in container
docker exec elite-quiz-admin-web env | grep -E "DB_|JWT_|REST_"

# Update .env file
nano .env

# Reload environment (restart containers)
docker-compose down
docker-compose up -d
```

### Testing

```bash
# Test database connection
docker exec elite-quiz-admin-web php -r "try { \$pdo = new PDO('mysql:host=elite-quiz-admin-db;dbname=elite_quiz_237', 'root', getenv('DB_PASSWORD')); echo 'OK'; } catch (Exception \$e) { echo 'FAILED'; }"

# Check web server
curl http://localhost:8080
```

---

## Security

### Security Features

✅ **All secrets moved to environment variables**
- Database credentials
- JWT secret key
- REST API credentials

✅ **Files excluded from version control**
- `.env` file
- `firebase_config.json`
- Database files and backups

✅ **No hardcoded passwords**
- All sensitive values read from environment variables
- Secure defaults (no password defaults)

### Security Checklist

1. **Rotate all exposed secrets immediately**
   - Change database password from default
   - Generate new JWT secret key
   - Change REST API credentials
   - Regenerate Firebase service account key

2. **Secure file permissions**
   ```bash
   chmod 600 .env
   chmod 600 Admin\ Panel/src/web/public/assets/firebase_config.json
   ```

3. **Never commit secrets**
   - Verify `.env` is in `.gitignore`
   - Verify `firebase_config.json` is in `.gitignore`
   - Review git history for exposed secrets

4. **Regular maintenance**
   - Rotate secrets every 90 days
   - Review access logs monthly
   - Update dependencies regularly


---

## Troubleshooting

### Database Connection Error

**Symptoms:** `Access denied for user 'root'@'...' (using password: YES)`

**Solution:**
```bash
# Check if database is ready
docker-compose logs db | grep "ready for connections"

# Update password manually
DB_PASS=$(grep "^DB_PASSWORD=" .env | cut -d '=' -f2)
docker exec elite-quiz-admin-db mysql -uroot -prootpassword -e "ALTER USER 'root'@'%' IDENTIFIED BY '$DB_PASS'; ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;" 2>/dev/null

# Restart web container
docker-compose restart web
```

### Port Already in Use

**Symptoms:** `Bind for 0.0.0.0:8080 failed: port is already allocated`

**Solution:**
```bash
# Check what's using the port
lsof -i :8080  # For web
lsof -i :3310  # For database
lsof -i :8090  # For phpMyAdmin

# Change ports in .env file
nano .env
# Update: APP_PORT=8081, DB_PORT=3311, PHPMYADMIN_PORT=8091

# Restart containers
docker-compose down
docker-compose up -d
```

### Environment Variables Not Loading

**Symptoms:** Application uses default values instead of `.env` values

**Solution:**
```bash
# Verify .env file exists
ls -la .env

# Check file permissions
chmod 600 .env

# Verify environment variables in container
docker exec elite-quiz-admin-web env | grep -E "DB_|JWT_|REST_"

# Restart containers
docker-compose restart
```

### Container Won't Start

**Solution:**
```bash
# Check logs
docker-compose logs

# Check container status
docker-compose ps

# Rebuild containers
docker-compose down
docker-compose up -d --build
```

### Reset Everything (Fresh Start)

⚠️ **WARNING:** This deletes all data

```bash
# Stop and remove everything
docker-compose down -v

# Remove .env
rm -f .env

# Regenerate secrets
./scripts/generate-secrets.sh
# Answer 'y' when prompted

# Set permissions
chmod 600 .env

# Start fresh
docker-compose up -d
```

---

## Additional Resources

### Scripts

- `start-panel.sh` - Automated setup script (main entry point)
- `scripts/generate-secrets.sh` - Secret generation script
- `scripts/export-db.sh` - Database export utility
- `scripts/import-db.sh` - Database import utility

### Project Structure

```
.
├── Admin Panel/
│   ├── src/
│   │   ├── web/
│   │   │   └── public/          # Application files
│   │   └── database/            # Database files (excluded from git)
│   └── infra/
│       └── Dockerfile           # Docker image definition
├── docker-compose.yml            # Docker Compose configuration
├── start-panel.sh                 # Main setup script
├── scripts/                       # Utility scripts
│   ├── generate-secrets.sh        # Secret generation
│   ├── export-db.sh              # Database export
│   └── import-db.sh               # Database import
├── .env                           # Environment variables (not in git)
├── .gitignore                     # Git ignore rules
└── README.md                      # This file
```

### Support

For issues and questions:
1. Check the troubleshooting section above
2. Check container logs: `docker-compose logs -f`

---

## License

[Add your license information here]

---

## Changelog

### Version 2.3.7

**Security Improvements:**
- ✅ All secrets moved to environment variables
- ✅ `.env` file excluded from version control
- ✅ `firebase_config.json` excluded from version control
- ✅ No hardcoded passwords in code
- ✅ Secure defaults implemented

**New Features:**
- ✅ Automated setup script (`start-panel.sh`)
- ✅ Secret generation script (`scripts/generate-secrets.sh`)
- ✅ Environment variable support
- ✅ Comprehensive documentation

---

**Last Updated:** December 2025

