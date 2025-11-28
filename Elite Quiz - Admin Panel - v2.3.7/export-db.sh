#!/bin/bash

# Export database content to SQL file
# Usage: ./export-db.sh [output_file]

OUTPUT_FILE="${1:-./Admin Panel/src/database-backups/backups/backup-$(date +%Y%m%d-%H%M%S).sql}"
DB_NAME="${DB_NAME:-elite_quiz_237}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-rootpassword}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3310}"

echo "Exporting database ${DB_NAME} to ${OUTPUT_FILE}..."

# Ensure the directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Export using mysqldump from the container
docker exec elite-quiz-admin-db mysqldump \
  -u "${DB_USER}" \
  -p"${DB_PASSWORD}" \
  --single-transaction \
  --routines \
  --triggers \
  "${DB_NAME}" > "${OUTPUT_FILE}"

if [ $? -eq 0 ]; then
  echo "Database exported successfully to ${OUTPUT_FILE}"
  echo "File size: $(du -h "${OUTPUT_FILE}" | cut -f1)"
else
  echo "Error: Database export failed"
  exit 1
fi

