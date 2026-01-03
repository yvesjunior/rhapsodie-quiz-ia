#!/bin/bash

# ============================================
# Rhapsodie Quiz IA - Mobile App Build Script
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MOBILE_DIR="$PROJECT_ROOT/src/mobile"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Rhapsodie Quiz IA - Mobile App Build                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
PLATFORM=""
BUILD_TYPE="release"
CLEAN=false

show_help() {
    echo "Usage: ./build-mobile.sh [PLATFORM] [OPTIONS]"
    echo ""
    echo "Platforms:"
    echo "  android     Build Android APK/AAB"
    echo "  ios         Build iOS IPA (requires macOS)"
    echo "  all         Build for both platforms"
    echo ""
    echo "Options:"
    echo "  --debug     Build debug version"
    echo "  --release   Build release version (default)"
    echo "  --clean     Clean build before building"
    echo "  --apk       Build APK only (Android)"
    echo "  --aab       Build App Bundle (Android, for Play Store)"
    echo "  --help, -h  Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./build-mobile.sh android --release"
    echo "  ./build-mobile.sh ios --clean"
    echo "  ./build-mobile.sh android --aab"
    echo ""
}

ANDROID_FORMAT="apk"

while [[ $# -gt 0 ]]; do
    case $1 in
        android|ios|all)
            PLATFORM=$1
            shift
            ;;
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --apk)
            ANDROID_FORMAT="apk"
            shift
            ;;
        --aab)
            ANDROID_FORMAT="appbundle"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$PLATFORM" ]; then
    echo -e "${RED}❌ Please specify a platform: android, ios, or all${NC}"
    show_help
    exit 1
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    exit 1
fi

cd "$MOBILE_DIR"

# ============================================
# PRE-BUILD CHECKS
# ============================================
echo -e "${BLUE}🔍 Pre-build checks...${NC}"

# Check firebase_options.dart
if [ ! -f "lib/firebase_options.dart" ]; then
    echo -e "${RED}❌ firebase_options.dart not found!${NC}"
    echo -e "${YELLOW}   Run: flutterfire configure${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All checks passed${NC}"
echo ""

# ============================================
# CLEAN BUILD
# ============================================
if [ "$CLEAN" = true ]; then
    echo -e "${BLUE}🧹 Cleaning build artifacts...${NC}"
    flutter clean
    rm -rf build/
    flutter pub get
    echo -e "${GREEN}✓ Clean complete${NC}"
    echo ""
fi

# ============================================
# GET DEPENDENCIES
# ============================================
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies ready${NC}"
echo ""

# ============================================
# BUILD FUNCTIONS
# ============================================
build_android() {
    echo -e "${BLUE}🤖 Building Android ($BUILD_TYPE)...${NC}"
    
    if [ "$ANDROID_FORMAT" = "appbundle" ]; then
        echo -e "${CYAN}   Building App Bundle (AAB)...${NC}"
        flutter build appbundle --$BUILD_TYPE
        
        AAB_PATH="build/app/outputs/bundle/${BUILD_TYPE}/app-${BUILD_TYPE}.aab"
        if [ -f "$AAB_PATH" ]; then
            echo -e "${GREEN}✓ AAB built: $AAB_PATH${NC}"
            
            # Copy to output folder
            OUTPUT_DIR="$PROJECT_ROOT/builds/android"
            mkdir -p "$OUTPUT_DIR"
            cp "$AAB_PATH" "$OUTPUT_DIR/rhapsody-quiz-$(date +%Y%m%d).aab"
            echo -e "${GREEN}✓ Copied to: $OUTPUT_DIR/rhapsody-quiz-$(date +%Y%m%d).aab${NC}"
        fi
    else
        echo -e "${CYAN}   Building APK...${NC}"
        flutter build apk --$BUILD_TYPE
        
        APK_PATH="build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk"
        if [ -f "$APK_PATH" ]; then
            echo -e "${GREEN}✓ APK built: $APK_PATH${NC}"
            
            # Copy to output folder
            OUTPUT_DIR="$PROJECT_ROOT/builds/android"
            mkdir -p "$OUTPUT_DIR"
            cp "$APK_PATH" "$OUTPUT_DIR/rhapsody-quiz-$(date +%Y%m%d).apk"
            echo -e "${GREEN}✓ Copied to: $OUTPUT_DIR/rhapsody-quiz-$(date +%Y%m%d).apk${NC}"
        fi
    fi
}

build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}❌ iOS builds require macOS${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🍎 Building iOS ($BUILD_TYPE)...${NC}"
    
    # Build iOS
    flutter build ios --$BUILD_TYPE --no-codesign
    
    echo -e "${GREEN}✓ iOS build complete${NC}"
    echo -e "${YELLOW}   Open Xcode to archive and distribute:${NC}"
    echo -e "${YELLOW}   open ios/Runner.xcworkspace${NC}"
    echo ""
    echo -e "${BLUE}📝 Next steps for App Store:${NC}"
    echo -e "   1. Open Runner.xcworkspace in Xcode"
    echo -e "   2. Select 'Any iOS Device' as build target"
    echo -e "   3. Product → Archive"
    echo -e "   4. Distribute App → App Store Connect"
}

# ============================================
# BUILD
# ============================================
case $PLATFORM in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    all)
        build_android
        echo ""
        build_ios
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Build Complete!                                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show build outputs
if [ -d "$PROJECT_ROOT/builds" ]; then
    echo -e "${BLUE}📦 Build outputs:${NC}"
    find "$PROJECT_ROOT/builds" -type f -name "*.apk" -o -name "*.aab" -o -name "*.ipa" 2>/dev/null | while read file; do
        SIZE=$(du -h "$file" | cut -f1)
        echo -e "   ${GREEN}$file${NC} (${SIZE})"
    done
    echo ""
fi

