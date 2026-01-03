#!/bin/bash

# ============================================
# Clear Today's Daily Contest
# ============================================
# Use this to test cron job creation of daily contests
# User scores are preserved!

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

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Determine docker-compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Clear Today's Daily Contest                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get today's date - try from cron container first, fallback to db container or local
if docker exec rhapsody-cron date +%Y-%m-%d &>/dev/null; then
    TODAY=$(docker exec rhapsody-cron date +%Y-%m-%d)
elif docker exec rhapsody-db date +%Y-%m-%d &>/dev/null; then
    TODAY=$(docker exec rhapsody-db date +%Y-%m-%d)
else
    TODAY=$(date +%Y-%m-%d)
fi
echo -e "${BLUE}Today's date: ${GREEN}$TODAY${NC}"
echo ""

# Default DB_NAME if not set
DB_NAME="${DB_NAME:-elite_quiz_237}"

# Check if DB container is running
if ! docker exec rhapsody-db echo "ok" &>/dev/null; then
    echo -e "${RED}Error: rhapsody-db container is not running${NC}"
    echo -e "${YELLOW}Start it with: docker compose up -d rhapsody-db${NC}"
    exit 1
fi

# Check if DB_PASSWORD is set
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: DB_PASSWORD is not set in .env${NC}"
    exit 1
fi

echo -e "${BLUE}Checking database...${NC}"

# Determine MySQL client command (mariadb for production, mysql for local dev)
if docker exec rhapsody-db which mariadb &>/dev/null; then
    MYSQL_CMD="mariadb"
else
    MYSQL_CMD="mysql"
fi

# Check if today's contest exists (filter out MySQL warnings)
CONTEST_INFO=$(docker exec rhapsody-db $MYSQL_CMD -u root -p"$DB_PASSWORD" "$DB_NAME" -N -e "
SELECT id, name FROM tbl_contest 
WHERE DATE(start_date) = '$TODAY' AND contest_type = 'daily'
LIMIT 1;
" 2>&1 | grep -v "^\[Warning\]\|^mysql:\|^mariadb:")

# Check for connection errors
if echo "$CONTEST_INFO" | grep -qi "error\|denied\|can't connect\|unknown"; then
    echo -e "${RED}Database error: $CONTEST_INFO${NC}"
    exit 1
fi

# Clean up any remaining whitespace
CONTEST_INFO=$(echo "$CONTEST_INFO" | sed '/^$/d')

if [ -z "$CONTEST_INFO" ]; then
    echo -e "${YELLOW}No daily contest found for today ($TODAY)${NC}"
    echo -e "${GREEN}Cron job can create a new one.${NC}"
    exit 0
fi

CONTEST_ID=$(echo "$CONTEST_INFO" | head -1 | cut -f1)
CONTEST_NAME=$(echo "$CONTEST_INFO" | head -1 | cut -f2)

echo -e "${YELLOW}Found today's contest:${NC}"
echo -e "  ID: ${GREEN}$CONTEST_ID${NC}"
echo -e "  Name: ${GREEN}$CONTEST_NAME${NC}"
echo ""

# Confirm deletion
read -p "Delete this contest? (User scores will be preserved) [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Deleting contest...${NC}"

# Delete contest questions first (foreign key constraint)
docker exec rhapsody-db $MYSQL_CMD -u root -p"$DB_PASSWORD" "$DB_NAME" -e "
DELETE FROM tbl_contest_question WHERE contest_id = $CONTEST_ID;
" 2>/dev/null

# Delete the contest (user scores in tbl_contest_leaderboard are preserved)
docker exec rhapsody-db $MYSQL_CMD -u root -p"$DB_PASSWORD" "$DB_NAME" -e "
DELETE FROM tbl_contest WHERE id = $CONTEST_ID;
" 2>/dev/null

echo -e "${GREEN}✓ Contest deleted successfully!${NC}"
echo ""
echo -e "${BLUE}You can now:${NC}"
echo -e "  1. Wait for cron to create a new contest at the scheduled time"
echo -e "  2. Or manually trigger: ${YELLOW}docker exec rhapsody-web curl -s http://localhost/index.php/Elite_Cron_Job${NC}"
echo ""

