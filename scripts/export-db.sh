#!/bin/bash

# Export database content to SQL file
# Usage: ./scripts/export-db.sh [output_file]

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables from .env if it exists
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | grep -v '^$' | xargs)
fi

OUTPUT_FILE="${1:-$PROJECT_ROOT/Admin Panel/src/database-backups/backups/backup-$(date +%Y%m%d-%H%M%S).sql}"
DB_NAME="${DB_NAME:-elite_quiz_237}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3310}"

# Validate required variables
if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD not set. Please set it in .env file or as environment variable."
    exit 1
fi

echo "Exporting database ${DB_NAME} to ${OUTPUT_FILE}..."
echo "Using credentials from .env file"

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

