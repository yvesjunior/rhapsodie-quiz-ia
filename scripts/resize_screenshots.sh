#!/bin/bash

# ============================================
# Resize Screenshots for App Store
# ============================================
# Resizes screenshots to required Apple App Store sizes

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIR="$PROJECT_ROOT/screenshot"
OUTPUT_DIR="$PROJECT_ROOT/screenshot/resized"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   App Store Screenshot Resizer                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${YELLOW}ImageMagick not found. Installing...${NC}"
    if command -v brew &> /dev/null; then
        brew install imagemagick
    else
        echo "Please install ImageMagick: brew install imagemagick"
        exit 1
    fi
fi

# Check source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Create output directories
# iPhone
mkdir -p "$OUTPUT_DIR/6.9-inch"   # iPhone 16 Pro Max (1320x2868)
mkdir -p "$OUTPUT_DIR/6.7-inch"   # iPhone 15 Pro Max, 14 Pro Max (1290x2796)
mkdir -p "$OUTPUT_DIR/6.5-inch"   # iPhone 11 Pro Max, XS Max (1284x2778)
mkdir -p "$OUTPUT_DIR/5.5-inch"   # iPhone 8 Plus (1242x2208)
# iPad
mkdir -p "$OUTPUT_DIR/ipad-13-inch"   # iPad Pro 13" (2064x2752)
mkdir -p "$OUTPUT_DIR/ipad-12.9-inch" # iPad Pro 12.9" (2048x2732)

echo -e "${BLUE}Source: ${NC}$SOURCE_DIR"
echo -e "${BLUE}Output: ${NC}$OUTPUT_DIR"
echo ""

# Count source images
COUNT=$(ls -1 "$SOURCE_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo -e "${BLUE}Found ${GREEN}$COUNT${BLUE} screenshots to resize${NC}"
echo ""

# Resize each image
for img in "$SOURCE_DIR"/*.png; do
    if [ -f "$img" ]; then
        name=$(basename "$img")
        echo -e "Processing: ${GREEN}$name${NC}"
        
        # iPhone 6.9" (1320x2868) - iPhone 16 Pro Max
        magick "$img" -resize 1320x2868! "$OUTPUT_DIR/6.9-inch/$name"
        
        # iPhone 6.7" (1290x2796) - iPhone 15 Pro Max
        magick "$img" -resize 1290x2796! "$OUTPUT_DIR/6.7-inch/$name"
        
        # iPhone 6.5" (1284x2778) - iPhone 11 Pro Max
        magick "$img" -resize 1284x2778! "$OUTPUT_DIR/6.5-inch/$name"
        
        # iPhone 5.5" (1242x2208) - iPhone 8 Plus
        magick "$img" -resize 1242x2208! "$OUTPUT_DIR/5.5-inch/$name"
        
        # iPad Pro 13" (2064x2752)
        magick "$img" -resize 2064x2752! "$OUTPUT_DIR/ipad-13-inch/$name"
        
        # iPad Pro 12.9" (2048x2732)
        magick "$img" -resize 2048x2732! "$OUTPUT_DIR/ipad-12.9-inch/$name"
    fi
done

echo ""
echo -e "${GREEN}✓ Screenshots resized successfully!${NC}"
echo ""
echo -e "${BLUE}Output folders:${NC}"
echo -e "  📱 6.9-inch (iPhone 16 Pro Max):  ${GREEN}$OUTPUT_DIR/6.9-inch/${NC}"
echo -e "  📱 6.7-inch (iPhone 15 Pro Max):  ${GREEN}$OUTPUT_DIR/6.7-inch/${NC}"
echo -e "  📱 6.5-inch (iPhone 11 Pro Max):  ${GREEN}$OUTPUT_DIR/6.5-inch/${NC}"
echo -e "  📱 5.5-inch (iPhone 8 Plus):      ${GREEN}$OUTPUT_DIR/5.5-inch/${NC}"
echo -e "  📱 iPad 13-inch (iPad Pro 13\"):   ${GREEN}$OUTPUT_DIR/ipad-13-inch/${NC}"
echo -e "  📱 iPad 12.9-inch (iPad Pro):     ${GREEN}$OUTPUT_DIR/ipad-12.9-inch/${NC}"
echo ""
echo -e "${YELLOW}Upload these to App Store Connect:${NC}"
echo -e "  1. Go to appstoreconnect.apple.com"
echo -e "  2. Select your app → App Store → Screenshots"
echo -e "  iPhone:"
echo -e "    - 6.9-inch (iPhone 16 Pro Max)"
echo -e "    - 6.7-inch (iPhone 15 Pro Max)"
echo -e "    - 6.5-inch (iPhone 11 Pro Max)"
echo -e "  iPad:"
echo -e "    - 13-inch iPad Pro"
echo -e "    - 12.9-inch iPad Pro"
echo ""

