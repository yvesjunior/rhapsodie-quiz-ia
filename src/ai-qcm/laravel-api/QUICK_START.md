# 🚀 Quick Start Guide

## Complete Setup in 5 Steps

### 1. Create Laravel Project (if needed)
```bash
cd laravel-api
composer create-project laravel/laravel .
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

### 2. Copy API Files
Make sure all files from this directory are in place:
- Models in `app/Models/`
- Controllers in `app/Http/Controllers/API/`
- Migrations in `database/migrations/`
- Routes in `routes/api.php`
- Resources in `app/Http/Resources/`

### 3. Setup Environment
```bash
cp env.docker.example .env
```

### 4. Start Docker
```bash
docker-compose up -d --build
```

### 5. Initialize Laravel
```bash
make setup    # Installs dependencies, generates key, runs migrations
make token    # Creates admin user and shows API token
```

## That's it! 🎉

Your API is now running at: **http://localhost:8000/api**

Use the token from `make token` in your Python generator's API settings.

## Test the API

```bash
curl http://localhost:8000/api/qcm
```

## Next Steps

1. Generate QCM using Python script with `--api-url http://localhost:8000/api/qcm`
2. Build your mobile app to consume the API
3. Users can compete and see rankings!

