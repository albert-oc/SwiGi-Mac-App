#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/SwiGi/SwiGi.xcodeproj"
SCHEME="SwiGi"
CONFIG="Release"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/Release/SwiGi.app"
RELEASES_DIR="$ROOT/releases"
ARCH="x86_64"
ARCH_LABEL="intel"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$ROOT/SwiGi/SwiGi/Info.plist" 2>/dev/null || echo "1.0.0")
MIN_OS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" -showBuildSettings 2>/dev/null | awk -F' = ' '$1 == "    MACOSX_DEPLOYMENT_TARGET" {print $2; exit}')
MIN_OS="${MIN_OS:-13.0}"
MIN_OS_LABEL="macOS${MIN_OS%%.*}"
ZIP_NAME="SwiGi-${VERSION}-${MIN_OS_LABEL}-${ARCH_LABEL}.zip"

"$ROOT/scripts/build-hidapi-static.sh" "$ARCH"

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

if otool -L "$BINARY" | grep -q libhidapi; then
  echo "error: hidapi is still dynamically linked — static link failed" >&2
  otool -L "$BINARY" | grep hidapi
  exit 1
fi

echo "Smoke test: launch binary..."
"$BINARY" &
PID=$!
sleep 2
if kill -0 "$PID" 2>/dev/null; then
  kill "$PID" 2>/dev/null || true
  echo "Smoke test passed (process started)."
else
  echo "error: app exited immediately — launch failed" >&2
  exit 1
fi

mkdir -p "$RELEASES_DIR"
ZIP_PATH="$RELEASES_DIR/$ZIP_NAME"
rm -f "$ZIP_PATH"

echo "Creating $ZIP_PATH..."
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP_PATH"

echo "Done."
echo "  App:  $APP ($(lipo -info "$BINARY"))"
echo "  Zip:  $ZIP_PATH"
ls -lh "$ZIP_PATH"
