#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/SwiGi/SwiGi.xcodeproj"
SCHEME="SwiGi"
CONFIG="Release"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/Release/SwiGi.app"
RELEASES_DIR="$ROOT/releases"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$ROOT/SwiGi/SwiGi/Info.plist" 2>/dev/null || echo "1.0.0")
MIN_OS=$(/usr/libexec/PlistBuddy -c "Print :objects:PROJDEBUG000000000000001:buildSettings:MACOSX_DEPLOYMENT_TARGET" "$PROJECT/project.pbxproj" 2>/dev/null || true)
if [[ -z "$MIN_OS" ]]; then
  MIN_OS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | awk -F' = ' '/MACOSX_DEPLOYMENT_TARGET/{print $2; exit}')
fi
MIN_OS="${MIN_OS:-13.0}"
MIN_OS_LABEL="macOS${MIN_OS%%.*}"
ARCH="$(uname -m)"
ZIP_NAME="SwiGi-${VERSION}-${MIN_OS_LABEL}-${ARCH}.zip"

echo "Building SwiGi ($CONFIG)..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  SYMROOT="$BUILD_DIR" \
  OBJROOT="$BUILD_DIR/Intermediates" \
  -destination 'platform=macOS' \
  build

if [[ ! -d "$APP" ]]; then
  echo "error: expected app at $APP" >&2
  exit 1
fi

FRAMEWORKS="$APP/Contents/Frameworks"
mkdir -p "$FRAMEWORKS"

HIDAPI_SRC="$(brew --prefix hidapi 2>/dev/null)/lib/libhidapi.0.dylib"
if [[ ! -f "$HIDAPI_SRC" ]]; then
  HIDAPI_SRC="/opt/homebrew/lib/libhidapi.0.dylib"
fi
if [[ ! -f "$HIDAPI_SRC" ]]; then
  echo "error: libhidapi not found — run: brew install hidapi" >&2
  exit 1
fi

echo "Bundling libhidapi..."
cp "$HIDAPI_SRC" "$FRAMEWORKS/libhidapi.0.dylib"
chmod 755 "$FRAMEWORKS/libhidapi.0.dylib"

BINARY="$APP/Contents/MacOS/SwiGi"
install_name_tool -change "@rpath/libhidapi.0.dylib" "@executable_path/../Frameworks/libhidapi.0.dylib" "$BINARY" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/lib/libhidapi.0.dylib" "@executable_path/../Frameworks/libhidapi.0.dylib" "$BINARY" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/hidapi/lib/libhidapi.0.dylib" "@executable_path/../Frameworks/libhidapi.0.dylib" "$BINARY" 2>/dev/null || true
install_name_tool -id "@executable_path/../Frameworks/libhidapi.0.dylib" "$FRAMEWORKS/libhidapi.0.dylib"

mkdir -p "$RELEASES_DIR"
ZIP_PATH="$RELEASES_DIR/$ZIP_NAME"
rm -f "$ZIP_PATH"

echo "Creating $ZIP_PATH..."
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP_PATH"

echo "Done."
echo "  App:  $APP"
echo "  Zip:  $ZIP_PATH"
ls -lh "$ZIP_PATH"
