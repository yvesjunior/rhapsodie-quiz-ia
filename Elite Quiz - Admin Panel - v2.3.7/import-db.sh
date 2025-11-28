#!/bin/bash

# Import database content from SQL file
# Usage: ./import-db.sh [input_file]

INPUT_FILE="${1:-./Admin Panel/src/database/backup.sql}"
DB_NAME="${DB_NAME:-elite_quiz_237}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-rootpassword}"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File ${INPUT_FILE} not found"
  exit 1
fi

echo "Importing database from ${INPUT_FILE}..."

# Import using mysql from the container
docker exec -i elite-quiz-admin-db mysql \
  -u "${DB_USER}" \
  -p"${DB_PASSWORD}" \
  "${DB_NAME}" < "${INPUT_FILE}"

if [ $? -eq 0 ]; then
  echo "Database imported successfully from ${INPUT_FILE}"
else
  echo "Error: Database import failed"
  exit 1
fi

