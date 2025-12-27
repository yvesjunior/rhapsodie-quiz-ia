#!/bin/bash

# Script to initialize Laravel project if it doesn't exist

if [ ! -f "artisan" ]; then
    echo "Laravel project not found. Creating new Laravel project..."
    composer create-project laravel/laravel .
    echo "✅ Laravel project created"
else
    echo "✅ Laravel project already exists"
fi

# Install Sanctum
if ! grep -q "laravel/sanctum" composer.json; then
    echo "Installing Laravel Sanctum..."
    composer require laravel/sanctum
    php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
    echo "✅ Sanctum installed"
else
    echo "✅ Sanctum already installed"
fi

echo "✅ Laravel initialization complete!"

