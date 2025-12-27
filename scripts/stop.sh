#!/bin/bash

# ============================================
# Rhapsodie Quiz IA - Stop Script
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
echo -e "${BLUE}║   Rhapsodie Quiz IA - Platform Shutdown              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed.${NC}"
    exit 1
fi

# Determine docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Parse arguments
REMOVE_VOLUMES=false
REMOVE_IMAGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --volumes|-v)
            REMOVE_VOLUMES=true
            shift
            ;;
        --images|-i)
            REMOVE_IMAGES=true
            shift
            ;;
        --all|-a)
            REMOVE_VOLUMES=true
            REMOVE_IMAGES=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./stop.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --volumes, -v     Remove volumes when stopping"
            echo "  --images, -i      Remove images when stopping"
            echo "  --all, -a         Remove volumes and images"
            echo "  --help, -h        Show this help message"
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

# Check if containers are running
if ! $DOCKER_COMPOSE ps -q &> /dev/null || [ -z "$($DOCKER_COMPOSE ps -q)" ]; then
    echo -e "${YELLOW}⚠️  No containers are currently running${NC}"
    exit 0
fi

echo -e "${BLUE}📊 Current container status:${NC}"
$DOCKER_COMPOSE ps
echo ""

echo -e "${BLUE}🛑 Stopping containers...${NC}"

# Build stop command
STOP_CMD="down"

if [ "$REMOVE_VOLUMES" = true ]; then
    STOP_CMD="$STOP_CMD --volumes"
    echo -e "${YELLOW}⚠️  Volumes will be removed${NC}"
fi

if [ "$REMOVE_IMAGES" = true ]; then
    STOP_CMD="$STOP_CMD --rmi all"
    echo -e "${YELLOW}⚠️  Images will be removed${NC}"
fi

# Stop services
$DOCKER_COMPOSE $STOP_CMD

echo ""
echo -e "${GREEN}✅ Platform stopped successfully!${NC}"
echo ""

# Show final status
echo -e "${BLUE}📊 Final container status:${NC}"
$DOCKER_COMPOSE ps
echo ""

if [ "$REMOVE_VOLUMES" = false ] && [ "$REMOVE_IMAGES" = false ]; then
    echo -e "${BLUE}💡 Tip:${NC}"
    echo -e "   To remove volumes: ${YELLOW}./scripts/stop.sh --volumes${NC}"
    echo -e "   To remove images:   ${YELLOW}./scripts/stop.sh --images${NC}"
    echo -e "   To remove all:       ${YELLOW}./scripts/stop.sh --all${NC}"
    echo ""
fi

