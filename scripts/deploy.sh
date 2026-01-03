#!/bin/bash

# ============================================
# Rhapsodie Quiz IA - Production Deployment
# ============================================

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rhapsodie Quiz IA - Production Deployment           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Determine docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Parse arguments
BUILD=false
BACKUP=false
MIGRATE=false
QUICK=false

show_help() {
    echo "Usage: ./deploy.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --build       Rebuild Docker images before deploying"
    echo "  --backup      Backup database before deploying"
    echo "  --migrate     Run database migrations after deploy"
    echo "  --quick       Skip health checks for faster deploy"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh                    # Standard deploy"
    echo "  ./deploy.sh --build            # Rebuild and deploy"
    echo "  ./deploy.sh --build --backup   # Rebuild with backup"
    echo ""
    echo "Note: SSL is handled by your external Nginx (kiwanoinc.ca)"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD=true
            shift
            ;;
        --backup)
            BACKUP=true
            shift
            ;;
        --migrate)
            MIGRATE=true
            shift
            ;;
        --quick)
            QUICK=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# ============================================
# PRE-DEPLOYMENT CHECKS
# ============================================
echo -e "${BLUE}🔍 Pre-deployment checks...${NC}"

# Check .env file
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo -e "${YELLOW}   Copy .env.example to .env and configure it:${NC}"
    echo -e "${YELLOW}   cp .env.example .env${NC}"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Check required variables
REQUIRED_VARS=("DB_PASSWORD" "JWT_SECRET_KEY" "REST_API_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "   - $var"
    done
    exit 1
fi

# Check Firebase service account
if [ ! -f "firebase-service-account.json" ]; then
    echo -e "${YELLOW}⚠️  firebase-service-account.json not found!${NC}"
    echo -e "${YELLOW}   Push notifications will not work.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pre-deployment checks passed${NC}"
echo ""

# ============================================
# DATABASE BACKUP
# ============================================
if [ "$BACKUP" = true ]; then
    echo -e "${BLUE}💾 Creating database backup...${NC}"
    
    BACKUP_DIR="$PROJECT_ROOT/backups"
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if $DOCKER_COMPOSE exec -T rhapsody-db mysqldump -u root -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
        
        # Compress backup
        gzip "$BACKUP_FILE"
        echo -e "${GREEN}✓ Backup compressed: ${BACKUP_FILE}.gz${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not create backup (database might not be running)${NC}"
    fi
    echo ""
fi

# ============================================
# BUILD IMAGES
# ============================================
if [ "$BUILD" = true ]; then
    echo -e "${BLUE}🔨 Building Docker images...${NC}"
    $DOCKER_COMPOSE build --no-cache
    echo -e "${GREEN}✓ Images built successfully${NC}"
    echo ""
fi

# ============================================
# DEPLOY
# ============================================
echo -e "${BLUE}🚀 Deploying to production...${NC}"

# Build compose command (uses external Nginx for SSL)
COMPOSE_CMD="-f docker-compose.yml -f docker-compose.prod.yml"

# Pull latest images (for non-built images)
echo -e "${CYAN}   Pulling latest images...${NC}"
$DOCKER_COMPOSE $COMPOSE_CMD pull --ignore-pull-failures 2>/dev/null || true

# Start services
echo -e "${CYAN}   Starting services...${NC}"
$DOCKER_COMPOSE $COMPOSE_CMD up -d

# ============================================
# HEALTH CHECKS
# ============================================
if [ "$QUICK" = false ]; then
    echo ""
    echo -e "${BLUE}🏥 Running health checks...${NC}"
    
    # Wait for MySQL
    echo -e "${CYAN}   Waiting for MySQL...${NC}"
    MAX_RETRIES=60
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if $DOCKER_COMPOSE exec -T rhapsody-db mysqladmin ping -h localhost --silent 2>/dev/null; then
            echo -e "${GREEN}   ✓ MySQL is healthy${NC}"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep 1
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${RED}   ❌ MySQL health check failed${NC}"
        exit 1
    fi
    
    # Wait for Web Server
    echo -e "${CYAN}   Waiting for web server...${NC}"
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT:-8080}/ | grep -q "200\|302"; then
            echo -e "${GREEN}   ✓ Web server is healthy${NC}"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep 1
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${YELLOW}   ⚠️  Web server health check timed out${NC}"
    fi
    
    # Wait for Redis
    echo -e "${CYAN}   Waiting for Redis...${NC}"
    if $DOCKER_COMPOSE exec -T rhapsody-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo -e "${GREEN}   ✓ Redis is healthy${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Redis health check failed${NC}"
    fi
fi

# ============================================
# POST-DEPLOYMENT
# ============================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Deployment Complete!                              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 Container Status:${NC}"
$DOCKER_COMPOSE $COMPOSE_CMD ps
echo ""

echo -e "${BLUE}📍 Access Points:${NC}"
echo -e "   ${GREEN}Admin Panel:${NC}  https://kiwanoinc.ca"
echo -e "   ${GREEN}API Base:${NC}     https://kiwanoinc.ca/api/"
echo -e "   ${GREEN}Local (dev):${NC}  http://localhost:${APP_PORT:-8080}"
echo ""

echo -e "${BLUE}📝 Useful Commands:${NC}"
echo -e "   View logs:        ${YELLOW}$DOCKER_COMPOSE logs -f${NC}"
echo -e "   View web logs:    ${YELLOW}$DOCKER_COMPOSE logs -f rhapsody-web${NC}"
echo -e "   View cron logs:   ${YELLOW}$DOCKER_COMPOSE logs -f rhapsody-cron${NC}"
echo -e "   Stop services:    ${YELLOW}./scripts/stop.sh${NC}"
echo -e "   Restart:          ${YELLOW}$DOCKER_COMPOSE restart${NC}"
echo ""

echo -e "${BLUE}🔧 Production Tips:${NC}"
echo -e "   • Monitor logs for errors"
echo -e "   • Set up external monitoring (UptimeRobot, etc.)"
echo -e "   • Configure automatic backups"
echo -e "   • Set up log rotation"
echo ""

