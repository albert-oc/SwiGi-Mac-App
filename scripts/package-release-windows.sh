#!/bin/bash
# Build and package SwiGi for Windows x64 (run on macOS/Linux with .NET SDK, or Windows).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/SwiGi.Win/SwiGi.Win/SwiGi.Win.csproj"
CONFIG="Release"
RID="win-x64"
BUILD_DIR="$ROOT/build/win"
PUBLISH_DIR="$BUILD_DIR/publish"
RELEASES_DIR="$ROOT/releases"
NATIVE_DIR="$ROOT/native/win-x64"
HIDAPI_DLL="$NATIVE_DIR/hidapi.dll"

VERSION=$(grep -m1 '<Version>' "$ROOT/SwiGi.Win/SwiGi.Win/SwiGi.Win.csproj" | sed 's/.*<Version>\(.*\)<\/Version>.*/\1/')
VERSION="${VERSION:-1.0.0}"
ZIP_NAME="SwiGi-${VERSION}-Windows11-x64.zip"

fetch_hidapi() {
  if [[ -f "$HIDAPI_DLL" ]]; then
    return 0
  fi
  echo "Fetching hidapi.dll for Windows x64..."
  mkdir -p "$NATIVE_DIR"
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/hidapi-win.zip" \
    "https://github.com/libusb/hidapi/releases/download/hidapi-0.15.0/hidapi-win.zip"
  unzip -q "$tmp/hidapi-win.zip" -d "$tmp/extract"
  local dll
  dll=$(find "$tmp/extract" -name 'hidapi.dll' -path '*x64*' 2>/dev/null | head -1)
  if [[ -z "$dll" ]]; then
    dll=$(find "$tmp/extract" -name 'hidapi.dll' 2>/dev/null | head -1)
  fi
  if [[ -z "$dll" || ! -f "$dll" ]]; then
    echo "error: hidapi.dll not found in hidapi-win.zip" >&2
    rm -rf "$tmp"
    exit 1
  fi
  cp "$dll" "$HIDAPI_DLL"
  rm -rf "$tmp"
  echo "Installed $HIDAPI_DLL"
}

fetch_hidapi

echo "Publishing SwiGi ($CONFIG, $RID)..."
dotnet publish "$PROJECT" \
  -c "$CONFIG" \
  -r "$RID" \
  -o "$PUBLISH_DIR" \
  --self-contained false \
  -p:PublishSingleFile=false \
  -p:EnableWindowsTargeting=true

EXE="$PUBLISH_DIR/SwiGi.exe"
if [[ ! -f "$EXE" ]]; then
  echo "error: expected $EXE" >&2
  exit 1
fi

cp "$HIDAPI_DLL" "$PUBLISH_DIR/hidapi.dll"

# Bundle folder for distribution
STAGE="$BUILD_DIR/SwiGi"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp "$PUBLISH_DIR/SwiGi.exe" "$PUBLISH_DIR/hidapi.dll" "$STAGE/"
cp "$PUBLISH_DIR/SwiGi.runtimeconfig.json" "$STAGE/" 2>/dev/null || true
cp "$PUBLISH_DIR/SwiGi.dll" "$STAGE/" 2>/dev/null || true
for dep in "$PUBLISH_DIR"/*.dll; do
  [[ -f "$dep" ]] || continue
  base=$(basename "$dep")
  [[ "$base" == "hidapi.dll" ]] && continue
  cp "$dep" "$STAGE/" 2>/dev/null || true
done

cat > "$STAGE/README.txt" <<EOF
SwiGi $VERSION for Windows 11 / Windows 10 (x64)

1. Install .NET 8 Desktop Runtime if prompted:
   https://dotnet.microsoft.com/download/dotnet/8.0
2. Pair Logitech keyboard and mouse via Bluetooth.
3. Run SwiGi.exe — look for the icon in the system tray (near the clock).
4. Right-click tray icon → Start.
5. Press Easy-Switch on the keyboard.

If SmartScreen blocks the app: More info → Run anyway.
EOF

mkdir -p "$RELEASES_DIR"
ZIP_PATH="$RELEASES_DIR/$ZIP_NAME"
rm -f "$ZIP_PATH"
(cd "$BUILD_DIR" && ditto -c -k --sequesterRsrc --keepParent SwiGi "$ZIP_PATH")

echo "Done."
echo "  Publish: $PUBLISH_DIR"
echo "  Zip:     $ZIP_PATH"
ls -lh "$ZIP_PATH"
