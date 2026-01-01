#!/bin/bash
# Check Daily Contest Status
# Usage: ./scripts/check_daily_contest.sh

echo "==================================="
echo "Daily Contest Status Check"
echo "==================================="
echo ""

# Check if containers are running
if ! docker ps | grep -q rhapsody-db; then
    echo "❌ Error: rhapsody-db container is not running"
    echo "   Run: docker-compose up -d"
    exit 1
fi

# Get database password
DB_PASS=$(docker exec rhapsody-db printenv MYSQL_ROOT_PASSWORD)

echo "📊 Today's Daily Contest:"
echo ""

docker exec rhapsody-db mysql -u root -p"$DB_PASS" elite_quiz_237 -e "
SELECT 
    c.id,
    c.name,
    c.status,
    c.start_date,
    c.end_date,
    (SELECT COUNT(*) FROM tbl_contest_question WHERE contest_id = c.id) as questions,
    (SELECT COUNT(*) FROM tbl_contest_leaderboard WHERE contest_id = c.id) as participants
FROM tbl_contest c 
WHERE c.contest_type = 'daily' 
ORDER BY c.id DESC 
LIMIT 5;
" 2>/dev/null

echo ""
echo "📱 User Participation (last 5):"
echo ""

docker exec rhapsody-db mysql -u root -p"$DB_PASS" elite_quiz_237 -e "
SELECT 
    cl.contest_id,
    u.name as user_name,
    cl.score,
    cl.last_updated
FROM tbl_contest_leaderboard cl
JOIN tbl_users u ON cl.user_id = u.id
JOIN tbl_contest c ON cl.contest_id = c.id
WHERE c.contest_type = 'daily'
ORDER BY cl.id DESC
LIMIT 5;
" 2>/dev/null

echo ""
echo "==================================="


