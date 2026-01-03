#!/bin/bash

# ============================================
# Rhapsodie Quiz IA - Startup Script
# ============================================

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root directory
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rhapsodie Quiz IA - Platform Startup                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env from .env.example...${NC}"
    cp .env.example .env 2>/dev/null || true
    echo -e "${YELLOW}⚠️  Please edit .env with your configuration${NC}"
    echo ""
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Determine docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Parse arguments
START_AI=false
START_TOOLS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ai|--with-ai)
            START_AI=true
            shift
            ;;
        --tools|--with-tools)
            START_TOOLS=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./start.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ai, --with-ai      Start AI services (Laravel API)"
            echo "  --tools, --with-tools Start development tools (Redis Commander)"
            echo "  --help, -h           Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build profiles
PROFILES=""
if [ "$START_AI" = true ]; then
    PROFILES="$PROFILES --profile ai-services"
    echo -e "${GREEN}✓ AI services will be started${NC}"
fi

if [ "$START_TOOLS" = true ]; then
    PROFILES="$PROFILES --profile tools"
    echo -e "${GREEN}✓ Development tools will be started${NC}"
fi

echo ""
echo -e "${BLUE}🐳 Starting Docker containers...${NC}"

# Start services
if [ -n "$PROFILES" ]; then
    $DOCKER_COMPOSE $PROFILES up -d
else
    $DOCKER_COMPOSE up -d
fi

# Wait for MySQL to be ready
echo -e "${BLUE}⏳ Waiting for MySQL to be ready...${NC}"
sleep 5

MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if $DOCKER_COMPOSE exec -T rhapsody-db mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo -e "${GREEN}✓ MySQL is ready${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ MySQL failed to start${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Platform started successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Container status:${NC}"
$DOCKER_COMPOSE ps
echo ""
echo -e "${BLUE}📍 Access points:${NC}"
echo -e "   ${GREEN}Admin Panel:${NC}  http://localhost:${APP_PORT:-8080}"
echo -e "   ${GREEN}phpMyAdmin:${NC}   http://localhost:8090"
if [ "$START_TOOLS" = true ]; then
    echo -e "   ${GREEN}Redis Commander:${NC} http://localhost:8081"
fi
if [ "$START_AI" = true ]; then
    echo -e "   ${GREEN}AI API:${NC}        http://localhost:8000"
fi
echo ""
echo -e "${BLUE}📝 Useful commands:${NC}"
echo -e "   View logs:     ${YELLOW}$DOCKER_COMPOSE logs -f${NC}"
echo -e "   Stop:          ${YELLOW}./scripts/stop.sh${NC}"
echo -e "   Restart:       ${YELLOW}$DOCKER_COMPOSE restart${NC}"
echo ""

