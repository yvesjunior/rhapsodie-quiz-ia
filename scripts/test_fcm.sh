#!/bin/bash
# Test FCM Push Notifications
# Usage: ./scripts/test_fcm.sh

echo "==================================="
echo "FCM Push Notification Test"
echo "==================================="
echo ""

# Check if containers are running
if ! docker ps | grep -q rhapsody-web; then
    echo "❌ Error: rhapsody-web container is not running"
    echo "   Run: docker-compose up -d"
    exit 1
fi

echo "📱 Sending daily contest notification..."
echo ""

# Execute the notification command inside the container
docker exec rhapsody-web php -r "
require_once '/var/www/html/index.php';
" 2>/dev/null

# Use curl inside the container to call the API
RESULT=$(docker exec rhapsody-web curl -s http://localhost/index.php/Elite_Cron_Job/send_daily_contest_notifications 2>&1)

echo "$RESULT"
echo ""

if echo "$RESULT" | grep -q "Topic notification sent successfully"; then
    echo "✅ Notification sent successfully to topic 'daily_quiz'!"
elif echo "$RESULT" | grep -q "FCM Error"; then
    echo "❌ FCM notification failed"
    echo ""
    echo "Possible fixes:"
    echo "  1. Check credentials at credentials/firebase-service-account.json"
    echo "  2. Verify FCM API is enabled in Google Cloud Console"
else
    echo "⚠️  Unknown result - check output above"
fi

echo ""
echo "==================================="

