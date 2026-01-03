#!/bin/bash
set -e

# Set timezone at runtime
if [ -n "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
fi

# Export environment variables for cron
# Cron doesn't inherit environment variables, so we need to write them to a file
printenv | grep -E '^(DAILY_CONTEST_AUTO_CREATE|DAILY_CONTEST_HOUR|DB_|CI_ENV|REDIS_|TZ|NOTIFICATION_)' > /etc/environment

# Default notification hours if not set (24h format, comma-separated)
# Examples: "8,13,22" = 8AM, 1PM, 10PM
#           "0,12,18" = 12AM, 12PM, 6PM
#           "9,14,19,21" = 9AM, 2PM, 7PM, 9PM
NOTIFICATION_HOURS="${NOTIFICATION_HOURS:-8,13,22}"

# Daily contest creation hour (24h format, default: 0 = midnight)
# Examples: "0" = midnight, "17" = 5PM, "6" = 6AM
DAILY_CONTEST_HOUR="${DAILY_CONTEST_HOUR:-0}"

# Convert 24h hours to readable format
format_hours() {
    local hours="$1"
    local formatted=""
    IFS=',' read -ra HOUR_ARRAY <<< "$hours"
    for h in "${HOUR_ARRAY[@]}"; do
        h=$(echo "$h" | xargs)  # trim whitespace
        if [ "$h" -eq 0 ]; then
            formatted="${formatted}12:00 AM, "
        elif [ "$h" -eq 12 ]; then
            formatted="${formatted}12:00 PM, "
        elif [ "$h" -lt 12 ]; then
            formatted="${formatted}${h}:00 AM, "
        else
            formatted="${formatted}$((h-12)):00 PM, "
        fi
    done
    echo "${formatted%, }"  # Remove trailing comma
}

echo "==================================="
echo "Rhapsody Quiz Cron Service"
echo "==================================="
echo "Timezone: ${TZ:-America/Montreal} ($(date +%Z))"
echo "Current time: $(date)"
echo "DAILY_CONTEST_AUTO_CREATE: ${DAILY_CONTEST_AUTO_CREATE:-false}"
echo "DAILY_CONTEST_HOUR: ${DAILY_CONTEST_HOUR} ($(format_hours "$DAILY_CONTEST_HOUR"))"
echo "NOTIFICATION_HOURS: ${NOTIFICATION_HOURS}"
echo ""

if [ "${DAILY_CONTEST_AUTO_CREATE}" = "true" ]; then
    echo "✓ Automatic daily contest creation ENABLED"
    echo "  - Daily contest: $(format_hours "$DAILY_CONTEST_HOUR")"
    echo "  - Notifications: $(format_hours "$NOTIFICATION_HOURS")"
else
    echo "✗ Automatic daily contest creation DISABLED"
    echo "  Use create_daily_contest.php for manual creation"
fi

echo ""
echo "==================================="

# Create crontab with environment variable support
cat > /etc/cron.d/rhapsody-cron << CRONTAB
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Load environment variables
BASH_ENV=/etc/environment

# Rhapsody Quiz Cron Jobs
# Daily contest creation (configurable via DAILY_CONTEST_HOUR env var)
0 ${DAILY_CONTEST_HOUR} * * * root . /etc/environment && [ "\$DAILY_CONTEST_AUTO_CREATE" = "true" ] && curl -s http://rhapsody-web/index.php/Elite_Cron_Job >> /var/log/cron.log 2>&1

# Weekly rewards distribution - Every Sunday at 11:59 PM (end of week)
59 23 * * 0 root . /etc/environment && [ "\$DAILY_CONTEST_AUTO_CREATE" = "true" ] && curl -s http://rhapsody-web/index.php/Elite_Cron_Job/distribute_weekly_rewards >> /var/log/cron.log 2>&1

CRONTAB

# Add notification cron entries dynamically based on NOTIFICATION_HOURS
echo "# Daily contest reminder notifications (configured via NOTIFICATION_HOURS env var)" >> /etc/cron.d/rhapsody-cron
IFS=',' read -ra HOUR_ARRAY <<< "$NOTIFICATION_HOURS"
for hour in "${HOUR_ARRAY[@]}"; do
    hour=$(echo "$hour" | xargs)  # trim whitespace
    echo "0 $hour * * * root . /etc/environment && [ \"\$DAILY_CONTEST_AUTO_CREATE\" = \"true\" ] && curl -s http://rhapsody-web/index.php/Elite_Cron_Job/send_daily_contest_notifications >> /var/log/cron.log 2>&1" >> /etc/cron.d/rhapsody-cron
done

echo "" >> /etc/cron.d/rhapsody-cron

chmod 0644 /etc/cron.d/rhapsody-cron

# Show generated crontab
echo "Generated crontab:"
cat /etc/cron.d/rhapsody-cron
echo "==================================="

# Start cron in foreground
echo "Starting cron..."
cron -f

