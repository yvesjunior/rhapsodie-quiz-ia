#!/bin/bash
# Create Daily Contest manually
# Usage: ./scripts/create_daily_contest.sh [--force]

echo "==================================="
echo "Daily Contest Creator"
echo "==================================="
echo ""

# Check if containers are running
if ! docker ps | grep -q rhapsody-web; then
    echo "❌ Error: rhapsody-web container is not running"
    echo "   Run: docker-compose up -d"
    exit 1
fi

FORCE=""
if [ "$1" == "--force" ]; then
    FORCE="?force=1"
    echo "⚠️  Force mode: Will delete and recreate today's contest"
fi

echo "📅 Creating daily contest for today..."
echo ""

# Call the create daily contest endpoint
RESULT=$(docker exec rhapsody-web curl -s "http://localhost/index.php/Elite_Cron_Job/create_daily_contest${FORCE}" 2>&1)

echo "$RESULT"
echo ""

if echo "$RESULT" | grep -q "Error"; then
    echo "❌ Failed to create daily contest"
elif echo "$RESULT" | grep -q "already exists"; then
    echo "ℹ️  Contest already exists for today"
    echo "   Use --force to recreate"
else
    echo "✅ Daily contest created successfully!"
fi

echo ""
echo "==================================="


