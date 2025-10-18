#!/bin/bash
# YessFish Flutter App - Build Script for Worldstream CI/CD
# Triggered by GitHub webhook on push to main branch

export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
set -e  # Exit on error

PROJECT_DIR="/opt/yessfish-flutter-app"
FLUTTER_BIN="/root/flutter/bin/flutter"
LOG_DIR="/var/log/yessfish-flutter-builds"
DOWNLOAD_DIR="/home/admin/domains/yessfish.com/public_html/downloads/beta"
VERSION_JSON="/home/admin/domains/yessfish.com/public_html/downloads/beta/version.json"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create log directory if not exists
mkdir -p "$LOG_DIR"
mkdir -p "$DOWNLOAD_DIR"

# Start logging
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/flutter-build-$TIMESTAMP.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "════════════════════════════════════════════════════════════════"
echo "🚀 YessFish Flutter App - CI/CD Build"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📅 Build Time: $(date)"
echo "📁 Project: $PROJECT_DIR"
echo "📝 Log: $LOG_FILE"
echo ""

# Navigate to project
cd "$PROJECT_DIR" || exit 1

echo "═══ Step 1: Git Pull Latest Changes ═══"
git fetch origin
git reset --hard origin/main
git pull origin main
echo -e "${GREEN}✓ Git pull successful${NC}"
echo ""

# Get version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
BUILD_NUMBER=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f2)
echo "📦 Version: $VERSION (build $BUILD_NUMBER)"
echo ""

echo "═══ Step 2: Flutter Dependencies ═══"
$FLUTTER_BIN pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

echo "═══ Step 3: Clean Previous Build ═══"
$FLUTTER_BIN clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

echo "═══ Step 4: Build APK (Release) ═══"
echo "🏗️  Building Flutter APK..."
START_TIME=$(date +%s)

$FLUTTER_BIN build apk --release \
    --build-name="$VERSION" \
    --build-number="$BUILD_NUMBER"

END_TIME=$(date +%s)
BUILD_DURATION=$((END_TIME - START_TIME))

echo -e "${GREEN}✓ APK built in ${BUILD_DURATION}s${NC}"
echo ""

# APK location
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ APK not found at $APK_PATH${NC}"
    exit 1
fi

# Get APK info
APK_SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
APK_MD5=$(md5sum "$APK_PATH" | cut -d' ' -f1)

echo "═══ Step 5: Deploy to Production ═══"
echo "📦 APK Size: $APK_SIZE"
echo "🔐 MD5: $APK_MD5"
echo ""

# Copy APK to downloads directory
VERSIONED_APK="$DOWNLOAD_DIR/yessfish-flutter-v${VERSION}.apk"
LATEST_APK="$DOWNLOAD_DIR/yessfish-flutter-latest.apk"

cp "$APK_PATH" "$VERSIONED_APK"
cp "$APK_PATH" "$LATEST_APK"

echo -e "${GREEN}✓ APK copied to:${NC}"
echo "  - $VERSIONED_APK"
echo "  - $LATEST_APK"
echo ""

# Update version.json for in-app update checker
echo "═══ Step 6: Update version.json ═══"
cat > "$VERSION_JSON" << EOF
{
  "version": "$VERSION",
  "build_number": $BUILD_NUMBER,
  "download_url": "https://yessfish.com/downloads/beta/yessfish-flutter-latest.apk",
  "changelog": "Latest Flutter beta build",
  "released_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "min_supported_version": "1.0.0",
  "force_update": false,
  "apk_size_bytes": $(stat -f%z "$LATEST_APK" 2>/dev/null || stat -c%s "$LATEST_APK"),
  "md5": "$APK_MD5"
}
EOF

echo -e "${GREEN}✓ version.json updated${NC}"
echo ""

echo "═══ Step 7: Set Permissions ═══"
chown -R admin:admin "$DOWNLOAD_DIR"
chmod 644 "$DOWNLOAD_DIR"/*.apk
chmod 644 "$VERSION_JSON"
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ BUILD SUCCESSFUL!${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📱 Version: $VERSION (build $BUILD_NUMBER)"
echo "📦 APK Size: $APK_SIZE"
echo "🔐 MD5: $APK_MD5"
echo "⏱️  Build Time: ${BUILD_DURATION}s"
echo "🌐 Download: https://yessfish.com/downloads/beta/yessfish-flutter-latest.apk"
echo "📝 Version Info: https://yessfish.com/downloads/beta/version.json"
echo ""
echo "🎉 Beta testers can now download the new Flutter version!"
echo ""
echo "════════════════════════════════════════════════════════════════"

# Send notification (optional - can add Slack/email later)
# echo "📧 Sending notification to beta testers..."

exit 0

echo "═══ Step 8: Deploy to Production Server ═══"
PROD_SERVER="185.165.242.58"
PROD_PORT="2223"
PROD_USER="root"
PROD_PASS="Yessfish123!"
PROD_DEST="/home/admin/domains/yessfish.com/public_html/downloads/beta"

echo "📤 Deploying to production: $PROD_SERVER"

# Copy APK files
sshpass -p "$PROD_PASS" scp -P "$PROD_PORT" -o StrictHostKeyChecking=no \
    "$VERSIONED_APK" "$PROD_USER@$PROD_SERVER:$PROD_DEST/"

sshpass -p "$PROD_PASS" scp -P "$PROD_PORT" -o StrictHostKeyChecking=no \
    "$LATEST_APK" "$PROD_USER@$PROD_SERVER:$PROD_DEST/"

# Copy version.json
sshpass -p "$PROD_PASS" scp -P "$PROD_PORT" -o StrictHostKeyChecking=no \
    "$VERSION_JSON" "$PROD_USER@$PROD_SERVER:$PROD_DEST/"

# Set permissions on production
sshpass -p "$PROD_PASS" ssh -p "$PROD_PORT" -o StrictHostKeyChecking=no \
    "$PROD_USER@$PROD_SERVER" \
    "chown admin:admin $PROD_DEST/*.apk $PROD_DEST/version.json && chmod 644 $PROD_DEST/*.apk $PROD_DEST/version.json"

echo -e "${GREEN}✓ Files deployed to production server${NC}"
echo ""

