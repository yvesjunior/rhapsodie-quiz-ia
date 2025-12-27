# Docker Setup for Laravel QCM API

This guide will help you set up the Laravel API using Docker Compose with volume mounts for live code editing.

## Prerequisites

- Docker Desktop installed
- Docker Compose installed
- Composer installed (for initial Laravel setup)

## Initial Setup (First Time Only)

If you don't have a Laravel project yet, you have two options:

**Option A: Create Laravel project first (Recommended)**
```bash
cd laravel-api
composer create-project laravel/laravel temp
mv temp/* temp/.* . 2>/dev/null || true
rmdir temp
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

**Option B: Use the init script**
```bash
cd laravel-api
./init-laravel.sh
```

Then copy all the API files (models, controllers, migrations, routes) to their respective directories.

## Quick Start

**Option 1: Using Makefile (Easiest)**
```bash
cd laravel-api
cp env.docker.example .env
make setup      # Builds, installs, generates key, runs migrations
make token      # Creates admin user and outputs API token
```

**Option 2: Manual Steps**

1. **Navigate to the Laravel API directory:**
```bash
cd laravel-api
```

2. **Copy environment file:**
```bash
cp env.docker.example .env
```

3. **Build and start containers:**
```bash
docker-compose up -d --build
```

4. **Install Composer dependencies:**
```bash
docker-compose exec app composer install
```

5. **Generate application key:**
```bash
docker-compose exec app php artisan key:generate
```

6. **Run migrations:**
```bash
docker-compose exec app php artisan migrate
```

7. **Create API token for Python generator:**
```bash
docker-compose exec app php artisan tinker
```

In tinker:
```php
$user = \App\Models\User::firstOrCreate(
    ['email' => 'admin@qcm.com'],
    ['name' => 'Admin', 'password' => bcrypt('password')]
);
$token = $user->createToken('qcm-generator')->plainTextToken;
echo $token;
exit
```

## Services

The Docker Compose setup includes:

- **app** - Laravel PHP-FPM application (port 9000)
- **nginx** - Web server (port 8000)
- **db** - MySQL 8.0 database (port 3306)
- **redis** - Redis cache/session store (port 6379)

## Access Points

- **API**: http://localhost:8000/api
- **Database**: localhost:3306
  - User: `qcm_user`
  - Password: `password`
  - Database: `qcm_db`
- **Redis**: localhost:6379

## Useful Commands

### View logs
```bash
docker-compose logs -f app
docker-compose logs -f nginx
```

### Execute commands in container
```bash
docker-compose exec app php artisan migrate
docker-compose exec app composer install
docker-compose exec app php artisan cache:clear
```

### Stop containers
```bash
docker-compose down
```

### Stop and remove volumes (clean slate)
```bash
docker-compose down -v
```

### Rebuild containers
```bash
docker-compose up -d --build
```

## Volume Mounts

The source code is mounted as a volume, so any changes you make to the files will be immediately reflected in the container. No need to rebuild!

- `./:/var/www/html` - Your Laravel code is mounted here

## Database Persistence

The database data is stored in a Docker volume (`db_data`), so it persists even when containers are stopped.

## Troubleshooting

### Permission issues
If you encounter permission issues:
```bash
docker-compose exec app chown -R www-data:www-data /var/www/html/storage
docker-compose exec app chown -R www-data:www-data /var/www/html/bootstrap/cache
```

### Clear cache
```bash
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan route:clear
```

### Check container status
```bash
docker-compose ps
```

## Connecting Python Generator

In your Python script or Streamlit UI, use:
- **API URL**: `http://localhost:8000/api/qcm`
- **API Token**: (the token you generated in step 7)

## Production Considerations

For production, you should:
1. Set `APP_DEBUG=false` in `.env`
2. Change database passwords
3. Use proper SSL certificates
4. Configure proper CORS origins
5. Set up proper backup strategy for database

