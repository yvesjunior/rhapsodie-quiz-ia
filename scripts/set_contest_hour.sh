#!/bin/bash

# ============================================
# Set Daily Contest Hour
# ============================================
# Updates DAILY_CONTEST_HOUR in .env and restarts cron
#
# Usage:
#   ./scripts/set_contest_hour.sh 17    # Set to 5 PM
#   ./scripts/set_contest_hour.sh 0     # Set to midnight (default)
#   ./scripts/set_contest_hour.sh 8     # Set to 8 AM

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Check for argument
if [ -z "$1" ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Set Daily Contest Hour                               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Usage: ${GREEN}./scripts/set_contest_hour.sh <HOUR>${NC}"
    echo ""
    echo -e "Examples:"
    echo -e "  ${YELLOW}./scripts/set_contest_hour.sh 0${NC}   # Midnight (production default)"
    echo -e "  ${YELLOW}./scripts/set_contest_hour.sh 17${NC}  # 5:00 PM"
    echo -e "  ${YELLOW}./scripts/set_contest_hour.sh 8${NC}   # 8:00 AM"
    echo -e "  ${YELLOW}./scripts/set_contest_hour.sh 12${NC}  # 12:00 PM (noon)"
    echo ""
    
    # Show current setting
    if [ -f .env ]; then
        CURRENT=$(grep "^DAILY_CONTEST_HOUR=" .env 2>/dev/null | cut -d= -f2)
        if [ -n "$CURRENT" ]; then
            echo -e "Current setting: ${GREEN}DAILY_CONTEST_HOUR=$CURRENT${NC}"
        else
            echo -e "Current setting: ${YELLOW}Not set (default: 0)${NC}"
        fi
    fi
    exit 0
fi

HOUR="$1"

# Validate hour (0-23)
if ! [[ "$HOUR" =~ ^[0-9]+$ ]] || [ "$HOUR" -lt 0 ] || [ "$HOUR" -gt 23 ]; then
    echo -e "${RED}Error: Hour must be a number between 0 and 23${NC}"
    exit 1
fi

# Convert to readable format
if [ "$HOUR" -eq 0 ]; then
    READABLE="12:00 AM (midnight)"
elif [ "$HOUR" -eq 12 ]; then
    READABLE="12:00 PM (noon)"
elif [ "$HOUR" -lt 12 ]; then
    READABLE="${HOUR}:00 AM"
else
    READABLE="$((HOUR-12)):00 PM"
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Set Daily Contest Hour                               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Update .env
echo -e "${BLUE}Updating .env...${NC}"
sed -i.bak '/^DAILY_CONTEST_HOUR=/d' .env
echo "DAILY_CONTEST_HOUR=$HOUR" >> .env
rm -f .env.bak

echo -e "${GREEN}✓ Set DAILY_CONTEST_HOUR=$HOUR ($READABLE)${NC}"
echo ""

# Determine docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Check if cron container is running
if ! docker ps --format '{{.Names}}' | grep -q "rhapsody-cron"; then
    echo -e "${YELLOW}⚠️  rhapsody-cron container is not running${NC}"
    echo -e "${YELLOW}   Start it with: docker compose up -d${NC}"
    exit 0
fi

# Restart cron container
echo -e "${BLUE}Restarting cron container...${NC}"
$DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.prod.yml up -d --force-recreate rhapsody-cron 2>/dev/null || \
$DOCKER_COMPOSE up -d --force-recreate rhapsody-cron 2>/dev/null

# Wait for container to start
sleep 2

# Verify
echo ""
echo -e "${BLUE}Verifying configuration...${NC}"
docker logs rhapsody-cron 2>&1 | head -10

echo ""
echo -e "${GREEN}✓ Done! Daily contest will be created at $READABLE${NC}"
echo ""

