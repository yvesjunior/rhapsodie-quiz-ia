.PHONY: help start stop restart logs ps shell-mysql shell-redis backup restore clean

# Default target
help:
	@echo "Rhapsodie Quiz IA - Docker Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  start          Start all services"
	@echo "  start-ai       Start with AI services"
	@echo "  start-tools    Start with development tools"
	@echo "  stop           Stop all services"
	@echo "  restart        Restart all services"
	@echo "  logs           Show logs (all services)"
	@echo "  logs-admin     Show admin-web logs"
	@echo "  logs-mysql     Show MySQL logs"
	@echo "  ps             Show container status"
	@echo "  shell-mysql    Open MySQL shell"
	@echo "  shell-redis    Open Redis CLI"
	@echo "  shell-admin    Open shell in admin-web container"
	@echo "  backup         Backup MySQL database"
	@echo "  restore        Restore MySQL database (usage: make restore FILE=backup.sql)"
	@echo "  clean          Stop and remove all containers and volumes"
	@echo "  setup          Initial setup (create .env if needed)"
	@echo "  test           Test all services"

# Setup
setup:
	@if [ ! -f .env ]; then \
		echo "Creating .env file..."; \
		echo "DB_PASSWORD=rootpassword" > .env; \
		echo "DB_NAME=elite_quiz_237" >> .env; \
		echo "JWT_SECRET_KEY=$$(openssl rand -base64 32)" >> .env; \
		echo "REST_API_PASSWORD=admin123" >> .env; \
		echo ".env file created. Please review and update if needed."; \
	else \
		echo ".env file already exists."; \
	fi

# Start services
start: setup
	@echo "Starting services..."
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 5
	@make ps
	@echo ""
	@echo "✅ Services started!"
	@echo "📍 Admin Panel: http://localhost:8080"
	@echo "📍 phpMyAdmin:  http://localhost:8090"

start-ai: setup
	@echo "Starting services with AI..."
	docker-compose --profile ai-services up -d
	@make ps
	@echo ""
	@echo "✅ Services started with AI!"
	@echo "📍 Admin Panel: http://localhost:8080"
	@echo "📍 AI API:      http://localhost:8000"

start-tools: setup
	@echo "Starting services with tools..."
	docker-compose --profile tools up -d
	@make ps

# Stop services
stop:
	@echo "Stopping services..."
	docker-compose down

# Restart services
restart:
	@echo "Restarting services..."
	docker-compose restart
	@make ps

# Logs
logs:
	docker-compose logs -f

logs-admin:
	docker-compose logs -f admin-web

logs-mysql:
	docker-compose logs -f mysql

logs-redis:
	docker-compose logs -f redis

logs-queue:
	docker-compose logs -f admin-queue

# Status
ps:
	@docker-compose ps

# Shell access
shell-mysql:
	@docker-compose exec mysql mysql -uroot -p$${DB_PASSWORD:-rootpassword} $${DB_NAME:-elite_quiz_237}

shell-redis:
	@docker-compose exec redis redis-cli

shell-admin:
	@docker-compose exec admin-web /bin/bash

# Database operations
backup:
	@mkdir -p backups
	@echo "Backing up database..."
	@docker-compose exec -T mysql mysqldump -uroot -p$${DB_PASSWORD:-rootpassword} $${DB_NAME:-elite_quiz_237} > backups/backup-$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup created in backups/"

restore:
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Please specify FILE=backup.sql"; \
		exit 1; \
	fi
	@echo "Restoring database from $(FILE)..."
	@docker-compose exec -T mysql mysql -uroot -p$${DB_PASSWORD:-rootpassword} $${DB_NAME:-elite_quiz_237} < $(FILE)
	@echo "✅ Database restored"

# Cleanup
clean:
	@echo "⚠️  This will remove all containers and volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "✅ Cleaned up"; \
	else \
		echo "Cancelled"; \
	fi

# Test services
test:
	@echo "Testing services..."
	@echo "Testing MySQL..."
	@docker-compose exec -T mysql mysqladmin ping -h localhost --silent && echo "✅ MySQL OK" || echo "❌ MySQL FAILED"
	@echo "Testing Redis..."
	@docker-compose exec -T redis redis-cli ping | grep -q PONG && echo "✅ Redis OK" || echo "❌ Redis FAILED"
	@echo "Testing Admin Web..."
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q 200 && echo "✅ Admin Web OK" || echo "❌ Admin Web FAILED"

# Build
build:
	@echo "Building images..."
	docker-compose build

build-no-cache:
	@echo "Building images (no cache)..."
	docker-compose build --no-cache

# Update
update:
	@echo "Pulling latest images..."
	docker-compose pull
	@echo "Rebuilding containers..."
	docker-compose up -d --build

