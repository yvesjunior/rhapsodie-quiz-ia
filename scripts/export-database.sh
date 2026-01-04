#!/bin/bash

# ============================================
# Export Database - Rhapsody Quiz Admin DB
# ============================================
# This script exports the database from the Docker container
# before refactoring the application
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONTAINER_NAME="rhapsody-db"
# Note: Container name matches service name in docker-compose.yml

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root directory
cd "$PROJECT_ROOT"

# Load from root .env file
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | grep -v '^$' | xargs)
elif [ -f "$PROJECT_ROOT/admin/.env" ]; then
    # Fallback to admin/.env for backward compatibility
    export $(grep -v '^#' "$PROJECT_ROOT/admin/.env" | grep -v '^$' | xargs)
fi

DB_NAME="${DB_NAME:-elite_quiz_237}"
DB_USER="${DB_USER:-root}"

# Get password from container if not set
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(docker inspect ${CONTAINER_NAME} 2>/dev/null | grep -A 1 "MYSQL_ROOT_PASSWORD" | grep "Value" | cut -d'"' -f4 || echo "rootpassword")
fi

# Create backups directory
BACKUP_DIR="./database-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${BACKUP_DIR}/backup_${DB_NAME}_${TIMESTAMP}.sql"
OUTPUT_FILE_COMPRESSED="${OUTPUT_FILE}.gz"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Database Export - Rhapsody Quiz Admin DB              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}❌ Container ${CONTAINER_NAME} is not running${NC}"
    echo "Please start the container first:"
    echo "  cd admin && docker-compose up -d db"
    exit 1
fi

echo -e "${GREEN}✓ Container ${CONTAINER_NAME} is running${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"
echo -e "${GREEN}✓ Backup directory created: ${BACKUP_DIR}${NC}"

# Check database exists
echo -e "${BLUE}📊 Checking database...${NC}"
DB_EXISTS=$(docker exec ${CONTAINER_NAME} mysql -u${DB_USER} -p${DB_PASSWORD} -e "SHOW DATABASES LIKE '${DB_NAME}';" 2>/dev/null | grep -c "${DB_NAME}" || echo "0")

if [ "$DB_EXISTS" -eq "0" ]; then
    echo -e "${YELLOW}⚠️  Database ${DB_NAME} not found. Listing available databases:${NC}"
    docker exec ${CONTAINER_NAME} mysql -u${DB_USER} -p${DB_PASSWORD} -e "SHOW DATABASES;" 2>/dev/null
    exit 1
fi

echo -e "${GREEN}✓ Database ${DB_NAME} found${NC}"

# Get database size
echo -e "${BLUE}📏 Checking database size...${NC}"
DB_SIZE=$(docker exec ${CONTAINER_NAME} mysql -u${DB_USER} -p${DB_PASSWORD} -e "
SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB'
FROM information_schema.tables
WHERE table_schema='${DB_NAME}';
" 2>/dev/null | grep -v "DB Size" | grep -v "^$" | tail -1 | tr -d ' ' || echo "0")

if [ -n "$DB_SIZE" ] && [ "$DB_SIZE" != "NULL" ]; then
    echo -e "${GREEN}✓ Database size: ${DB_SIZE} MB${NC}"
else
    echo -e "${YELLOW}⚠️  Could not determine database size${NC}"
fi
echo ""

# Export database
echo -e "${BLUE}📦 Exporting database...${NC}"
echo -e "   Container: ${CONTAINER_NAME}"
echo -e "   Database:  ${DB_NAME}"
echo -e "   Output:    ${OUTPUT_FILE}"
echo ""

docker exec ${CONTAINER_NAME} mysqldump \
  -u${DB_USER} \
  -p${DB_PASSWORD} \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --add-drop-database \
  --databases ${DB_NAME} > "${OUTPUT_FILE}" 2>/dev/null

if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)
    echo -e "${GREEN}✅ Database exported successfully!${NC}"
    echo -e "   File: ${OUTPUT_FILE}"
    echo -e "   Size: ${FILE_SIZE}"
    echo ""
    
    # Compress the backup
    echo -e "${BLUE}🗜️  Compressing backup...${NC}"
    gzip -c "${OUTPUT_FILE}" > "${OUTPUT_FILE_COMPRESSED}"
    COMPRESSED_SIZE=$(du -h "${OUTPUT_FILE_COMPRESSED}" | cut -f1)
    echo -e "${GREEN}✅ Backup compressed!${NC}"
    echo -e "   Compressed file: ${OUTPUT_FILE_COMPRESSED}"
    echo -e "   Compressed size: ${COMPRESSED_SIZE}"
    echo ""
    
    # Create a restore script
    RESTORE_SCRIPT="${BACKUP_DIR}/restore_${TIMESTAMP}.sh"
    cat > "${RESTORE_SCRIPT}" << EOF
#!/bin/bash
# Restore script for backup: ${OUTPUT_FILE}
# Generated: $(date)

set -e

CONTAINER_NAME="${CONTAINER_NAME}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
BACKUP_FILE="${OUTPUT_FILE}"

echo "Restoring database from: \${BACKUP_FILE}"

# Check if backup file exists
if [ ! -f "\${BACKUP_FILE}" ]; then
    echo "Error: Backup file not found: \${BACKUP_FILE}"
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^\${CONTAINER_NAME}\$"; then
    echo "Error: Container \${CONTAINER_NAME} is not running"
    exit 1
fi

# Restore database
docker exec -i \${CONTAINER_NAME} mysql -u\${DB_USER} -p\${DB_PASSWORD} < \${BACKUP_FILE}

echo "✅ Database restored successfully!"
EOF
    chmod +x "${RESTORE_SCRIPT}"
    echo -e "${GREEN}✓ Restore script created: ${RESTORE_SCRIPT}${NC}"
    echo ""
    
    # Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Export Summary                                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "   ${GREEN}✓${NC} SQL Backup:     ${OUTPUT_FILE}"
    echo -e "   ${GREEN}✓${NC} Compressed:     ${OUTPUT_FILE_COMPRESSED}"
    echo -e "   ${GREEN}✓${NC} Restore Script:  ${RESTORE_SCRIPT}"
    echo ""
    echo -e "${YELLOW}💡 To restore this backup, run:${NC}"
    echo -e "   ${BLUE}${RESTORE_SCRIPT}${NC}"
    echo ""
    
else
    echo -e "${RED}❌ Database export failed${NC}"
    exit 1
fi

