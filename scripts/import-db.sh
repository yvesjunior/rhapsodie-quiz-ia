#!/bin/bash

# Import database content from SQL file
# Usage: ./scripts/import-db.sh [input_file]

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env from project root
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | grep -v '^$' | xargs)
fi

INPUT_FILE="${1:-$PROJECT_ROOT/database-backups/backup_elite_quiz_237_20251226_221111.sql}"
DB_NAME="${DB_NAME:-elite_quiz_237}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD}"
CONTAINER_NAME="${CONTAINER_NAME:-rhapsody-db}"

# Validate required variables
if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD not set. Please set it in .env file or as environment variable."
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File ${INPUT_FILE} not found"
  echo "Usage: ./scripts/import-db.sh [path_to_sql_file]"
  echo ""
  echo "Available backups:"
  ls -lh "$(dirname "$INPUT_FILE")"/*.sql 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' || echo "  No backups found"
  exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container ${CONTAINER_NAME} is not running"
    echo "Please start the containers first with: ./scripts/start.sh"
    exit 1
fi

echo "Importing database from ${INPUT_FILE}..."
echo "Using container: ${CONTAINER_NAME}"
echo "Database: ${DB_NAME}"

# Import using mysql from the container
docker exec -i ${CONTAINER_NAME} mysql \
  -u "${DB_USER}" \
  -p"${DB_PASSWORD}" \
  "${DB_NAME}" < "${INPUT_FILE}"

if [ $? -eq 0 ]; then
  echo "Database imported successfully from ${INPUT_FILE}"
else
  echo "Error: Database import failed"
  exit 1
fi

