.PHONY: up down build restart logs shell migrate install

# Start containers
up:
	docker-compose up -d

# Stop containers
down:
	docker-compose down

# Build containers
build:
	docker-compose up -d --build

# Restart containers
restart:
	docker-compose restart

# View logs
logs:
	docker-compose logs -f app

# Access shell in app container
shell:
	docker-compose exec app bash

# Run migrations
migrate:
	docker-compose exec app php artisan migrate

# Install dependencies
install:
	docker-compose exec app composer install

# Generate app key
key:
	docker-compose exec app php artisan key:generate

# Clear cache
clear:
	docker-compose exec app php artisan config:clear
	docker-compose exec app php artisan cache:clear
	docker-compose exec app php artisan route:clear

# Setup everything (first time)
setup: build install key migrate
	@echo "✅ Setup complete! API available at http://localhost:8000"

# Create admin user and token
token:
	@echo "Creating admin user and generating token..."
	@docker-compose exec -T app php artisan tinker <<< "echo \App\Models\User::firstOrCreate(['email' => 'admin@qcm.com'], ['name' => 'Admin', 'password' => bcrypt('password')])->createToken('qcm-generator')->plainTextToken;"

