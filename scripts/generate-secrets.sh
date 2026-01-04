#!/bin/bash

# Generate Secure Secrets for Rhapsody Quiz Admin Panel
# This script generates secure random secrets for use in .env file
# Usage: ./scripts/generate-secrets.sh

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root directory
cd "$PROJECT_ROOT"

echo "============================================"
echo "Rhapsody Quiz Admin Panel - Secret Generator"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating secure secrets...${NC}"
echo ""

# Generate JWT Secret (32+ characters)
JWT_SECRET=$(openssl rand -base64 32)
echo -e "${GREEN}JWT_SECRET_KEY:${NC}"
echo "$JWT_SECRET"
echo ""

# Generate Database Password (24+ characters)
DB_PASSWORD=$(openssl rand -base64 24)
echo -e "${GREEN}DB_PASSWORD:${NC}"
echo "$DB_PASSWORD"
echo ""

# Generate REST API Password (16+ characters)
REST_PASSWORD=$(openssl rand -base64 16)
echo -e "${GREEN}REST_API_PASSWORD:${NC}"
echo "$REST_PASSWORD"
echo ""

echo "============================================"
echo -e "${YELLOW}Copy these values to your .env file${NC}"
echo "============================================"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Keep these secrets secure"
echo "   - Never commit them to version control"
echo "   - Rotate them regularly (every 90 days)"
echo ""

# Optionally create .env file
read -p "Would you like to create/update .env file with these values? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ENV_FILE=".env"
    
    # Check if .env exists
    if [ -f "$ENV_FILE" ]; then
        echo "⚠️  .env file already exists. Creating backup..."
        cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create or update .env file
    if [ ! -f "$ENV_FILE" ]; then
        # Create from .env.example if it exists
        if [ -f ".env.example" ]; then
            cp .env.example "$ENV_FILE"
        else
            # Create basic .env file
            cat > "$ENV_FILE" << EOF
# Database Configuration
DB_HOST=elite-quiz-admin-db
DB_USER=root
DB_PASSWORD=
DB_NAME=elite_quiz_237
DB_PORT=3306

# JWT Secret Key
JWT_SECRET_KEY=

# REST API Credentials
REST_API_USERNAME=admin
REST_API_PASSWORD=

# Application Environment
CI_ENV=development

# Docker Configuration
APP_PORT=8080
DB_PORT=3310
PHPMYADMIN_PORT=8090
EOF
        fi
    fi
    
    # Update values in .env file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" "$ENV_FILE"
        sed -i '' "s|^JWT_SECRET_KEY=.*|JWT_SECRET_KEY=$JWT_SECRET|" "$ENV_FILE"
        sed -i '' "s|^REST_API_PASSWORD=.*|REST_API_PASSWORD=$REST_PASSWORD|" "$ENV_FILE"
    else
        # Linux
        sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" "$ENV_FILE"
        sed -i "s|^JWT_SECRET_KEY=.*|JWT_SECRET_KEY=$JWT_SECRET|" "$ENV_FILE"
        sed -i "s|^REST_API_PASSWORD=.*|REST_API_PASSWORD=$REST_PASSWORD|" "$ENV_FILE"
    fi
    
    # Set proper permissions
    chmod 600 "$ENV_FILE"
    
    echo -e "${GREEN}✓ .env file updated successfully!${NC}"
    echo "  File permissions set to 600 (read/write owner only)"
    echo ""
    echo "⚠️  Next steps:"
    echo "   1. Review the .env file and update any other values"
    echo "   2. Restart your Docker containers or web server"
    echo "   3. Test the application to verify everything works"
else
    echo "Secrets generated. Please manually add them to your .env file."
fi

echo ""
echo "Done!"

