#!/bin/bash
# Generate macOS AppIcon.appiconset PNGs from a 1024x1024 source image.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${1:-$ROOT/assets/SwiGi-icon-1024.png}"
ICONSET="$ROOT/SwiGi/SwiGi/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SOURCE" ]]; then
  echo "error: source image not found: $SOURCE" >&2
  exit 1
fi

mkdir -p "$ICONSET"

generate() {
  local name="$1"
  local size="$2"
  sips -z "$size" "$size" "$SOURCE" --out "$ICONSET/$name" >/dev/null
}

generate icon_16x16.png 16
generate icon_16x16@2x.png 32
generate icon_32x32.png 32
generate icon_32x32@2x.png 64
generate icon_128x128.png 128
generate icon_128x128@2x.png 256
generate icon_256x256.png 256
generate icon_256x256@2x.png 512
generate icon_512x512.png 512
generate icon_512x512@2x.png 1024

echo "Generated AppIcon set in $ICONSET"
