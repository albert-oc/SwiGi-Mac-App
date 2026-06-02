#!/bin/bash
# Build x86_64 libhidapi for Intel Mac release packaging.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/vendor/hidapi-x86_64"
SRC="$VENDOR/src/hidapi"

if [[ ! -d "$SRC" ]]; then
  mkdir -p "$VENDOR/src"
  git clone --depth 1 --branch hidapi-0.15.0 https://github.com/libusb/hidapi.git "$SRC"
fi

mkdir -p "$VENDOR/lib" "$VENDOR/include/hidapi"

clang -arch x86_64 -O2 -dynamiclib \
  -I"$SRC/hidapi" \
  "$SRC/mac/hid.c" \
  -framework IOKit -framework CoreFoundation \
  -install_name "@executable_path/../Frameworks/libhidapi.0.dylib" \
  -compatibility_version 0.15.0 -current_version 0.15.0 \
  -o "$VENDOR/lib/libhidapi.0.dylib"

cp "$SRC/hidapi/hidapi.h" "$VENDOR/include/hidapi/"
cp "$SRC/mac/hidapi_darwin.h" "$VENDOR/include/hidapi/"
ln -sf libhidapi.0.dylib "$VENDOR/lib/libhidapi.dylib"

file "$VENDOR/lib/libhidapi.0.dylib"
echo "Built $VENDOR/lib/libhidapi.0.dylib"
