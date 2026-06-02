#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/SwiGi/SwiGi.xcodeproj"
SCHEME="SwiGi"
CONFIG="Release"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/Release/SwiGi.app"
RELEASES_DIR="$ROOT/releases"
VENDOR="$ROOT/vendor/hidapi-x86_64"
ARCH="x86_64"
ARCH_LABEL="intel"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$ROOT/SwiGi/SwiGi/Info.plist" 2>/dev/null || echo "1.0.0")
MIN_OS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" -showBuildSettings 2>/dev/null | awk -F' = ' '$1 == "    MACOSX_DEPLOYMENT_TARGET" {print $2; exit}')
if [[ -z "$MIN_OS" ]]; then
  MIN_OS="13.0"
fi
MIN_OS_LABEL="macOS${MIN_OS%%.*}"
ZIP_NAME="SwiGi-${VERSION}-${MIN_OS_LABEL}-${ARCH_LABEL}.zip"

if [[ ! -f "$VENDOR/lib/libhidapi.0.dylib" ]]; then
  echo "Building vendored x86_64 hidapi..."
  "$ROOT/scripts/build-hidapi-x86_64.sh"
fi

echo "Building SwiGi ($CONFIG, $ARCH)..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  SYMROOT="$BUILD_DIR" \
  OBJROOT="$BUILD_DIR/Intermediates" \
  ARCHS="$ARCH" \
  ONLY_ACTIVE_ARCH=NO \
  -destination 'platform=macOS' \
  build

if [[ ! -d "$APP" ]]; then
  echo "error: expected app at $APP" >&2
  exit 1
fi

BINARY="$APP/Contents/MacOS/SwiGi"
APP_ARCH="$(lipo -info "$BINARY" 2>/dev/null | awk -F': ' '{print $NF}')"
if [[ "$APP_ARCH" != *x86_64* ]]; then
  echo "error: expected x86_64 binary, got: $APP_ARCH" >&2
  exit 1
fi

FRAMEWORKS="$APP/Contents/Frameworks"
mkdir -p "$FRAMEWORKS"

HIDAPI_SRC="$VENDOR/lib/libhidapi.0.dylib"
if [[ ! -f "$HIDAPI_SRC" ]]; then
  echo "error: $HIDAPI_SRC not found" >&2
  exit 1
fi

echo "Bundling x86_64 libhidapi..."
cp "$HIDAPI_SRC" "$FRAMEWORKS/libhidapi.0.dylib"
chmod 755 "$FRAMEWORKS/libhidapi.0.dylib"

install_name_tool -change "@rpath/libhidapi.0.dylib" "@executable_path/../Frameworks/libhidapi.0.dylib" "$BINARY" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/lib/libhidapi.0.dylib" "@executable_path/../Frameworks/libhidapi.0.dylib" "$BINARY" 2>/dev/null || true
install_name_tool -change "/usr/local/lib/libhidapi.0.dylib" "@executable_path/../Frameworks/libhidapi.0.dylib" "$BINARY" 2>/dev/null || true
install_name_tool -id "@executable_path/../Frameworks/libhidapi.0.dylib" "$FRAMEWORKS/libhidapi.0.dylib"

mkdir -p "$RELEASES_DIR"
ZIP_PATH="$RELEASES_DIR/$ZIP_NAME"
rm -f "$ZIP_PATH"

echo "Creating $ZIP_PATH..."
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP_PATH"

echo "Done."
echo "  App:  $APP ($(lipo -info "$BINARY"))"
echo "  Zip:  $ZIP_PATH"
ls -lh "$ZIP_PATH"
