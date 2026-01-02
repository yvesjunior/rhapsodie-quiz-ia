#!/bin/bash

# Test Weekly Rewards Distribution
# This shows what would happen without actually updating coins

echo "Testing Weekly Rewards..."
echo ""

curl -s "http://localhost:8080/index.php/Elite_Cron_Job/test_weekly_rewards"

echo ""
echo "---"
echo "To actually distribute rewards, run:"
echo "curl http://localhost:8080/index.php/Elite_Cron_Job/distribute_weekly_rewards"

