# Laravel QCM API - Quick Setup Guide

## Step 1: Install Laravel

```bash
composer create-project laravel/laravel qcm-api
cd qcm-api
```

## Step 2: Install Dependencies

```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

## Step 3: Copy Files

Copy all files from `laravel-api/` folder to your Laravel project:

- **Migrations**: Copy to `database/migrations/`
- **Models**: Copy to `app/Models/`
- **Controllers**: Copy to `app/Http/Controllers/API/`
- **Resources**: Copy to `app/Http/Resources/`
- **Routes**: Add routes to `routes/api.php`

## Step 4: Update User Model

Add to `app/Models/User.php`:

```php
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
    
    // Add this relationship
    public function scores(): HasMany
    {
        return $this->hasMany(UserScore::class);
    }
}
```

## Step 5: Configure CORS

Update `config/cors.php`:

```php
'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_origins' => ['*'], // Or specify your mobile app domain
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

## Step 6: Run Migrations

```bash
php artisan migrate
```

## Step 7: Create API Token for Python Generator

```bash
php artisan tinker
```

Then in tinker:
```php
$user = User::firstOrCreate(['email' => 'admin@example.com'], ['name' => 'Admin', 'password' => bcrypt('password')]);
$token = $user->createToken('qcm-generator')->plainTextToken;
echo $token;
```

Copy this token to use in Python script.

## Step 8: Start Server

```bash
php artisan serve
```

API will be available at: `http://localhost:8000/api`

## Step 9: Test API

Test with curl:
```bash
curl -X POST http://localhost:8000/api/qcm \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "Test QCM",
    "questions": [
      {
        "question": "Test question?",
        "options": ["A. Option 1", "B. Option 2"],
        "correct_answers": ["A"],
        "explanation": "Explanation here",
        "reference": "John 1:1"
      }
    ]
  }'
```

## API Endpoints Summary

### Public Endpoints
- `GET /api/qcm` - List all QCMs
- `GET /api/qcm/{id}` - Get specific QCM
- `POST /api/qcm/{id}/submit` - Submit answers
- `GET /api/qcm/{id}/leaderboard` - Get QCM leaderboard
- `GET /api/leaderboard` - Global leaderboard
- `POST /api/register` - Register user
- `POST /api/login` - Login user

### Protected Endpoints (require token)
- `POST /api/qcm` - Create QCM (for Python generator)
- `DELETE /api/qcm/{id}` - Delete QCM
- `GET /api/user/scores` - Get user scores
- `POST /api/logout` - Logout

## Python Integration

In your Python script, use:
```python
python pdf_to_qcm_full.py \
  --input file.pdf \
  --api-url http://localhost:8000/api/qcm \
  --api-token YOUR_TOKEN \
  --api-title "My QCM Title"
```

Or in Streamlit UI, enable "Push to Laravel API" and enter your API URL and token.

