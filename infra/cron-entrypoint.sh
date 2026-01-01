#!/bin/bash
set -e

# Set timezone at runtime
if [ -n "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
fi

# Export environment variables for cron
# Cron doesn't inherit environment variables, so we need to write them to a file
printenv | grep -E '^(DAILY_CONTEST_AUTO_CREATE|DB_|CI_ENV|REDIS_|TZ)' > /etc/environment

echo "==================================="
echo "Rhapsody Quiz Cron Service"
echo "==================================="
echo "Timezone: ${TZ:-America/Montreal} ($(date +%Z))"
echo "Current time: $(date)"
echo "DAILY_CONTEST_AUTO_CREATE: ${DAILY_CONTEST_AUTO_CREATE:-false}"
echo ""

if [ "${DAILY_CONTEST_AUTO_CREATE}" = "true" ]; then
    echo "✓ Automatic daily contest creation ENABLED"
    echo "  - Daily contest: 00:00"
    echo "  - Notifications: 08:00, 13:00, 22:00"
else
    echo "✗ Automatic daily contest creation DISABLED"
    echo "  Use create_daily_contest.php for manual creation"
fi

echo ""
echo "==================================="

# Create crontab with environment variable support
cat > /etc/cron.d/rhapsody-cron << 'CRONTAB'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Load environment variables
BASH_ENV=/etc/environment

# Rhapsody Quiz Cron Jobs
# Daily contest creation at midnight
0 0 * * * root . /etc/environment && [ "$DAILY_CONTEST_AUTO_CREATE" = "true" ] && curl -s http://rhapsody-web/index.php/Elite_Cron_Job >> /var/log/cron.log 2>&1

# Daily contest notifications at 8AM, 1PM, 10PM
0 8 * * * root . /etc/environment && [ "$DAILY_CONTEST_AUTO_CREATE" = "true" ] && curl -s http://rhapsody-web/index.php/Elite_Cron_Job/send_daily_contest_notifications >> /var/log/cron.log 2>&1
0 13 * * * root . /etc/environment && [ "$DAILY_CONTEST_AUTO_CREATE" = "true" ] && curl -s http://rhapsody-web/index.php/Elite_Cron_Job/send_daily_contest_notifications >> /var/log/cron.log 2>&1
0 22 * * * root . /etc/environment && [ "$DAILY_CONTEST_AUTO_CREATE" = "true" ] && curl -s http://rhapsody-web/index.php/Elite_Cron_Job/send_daily_contest_notifications >> /var/log/cron.log 2>&1

CRONTAB

chmod 0644 /etc/cron.d/rhapsody-cron

# Start cron in foreground
echo "Starting cron..."
cron -f

