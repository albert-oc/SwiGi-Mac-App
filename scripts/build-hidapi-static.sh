#!/bin/bash
# Build static libhidapi.a for the given macOS architecture (arm64 or x86_64).
set -euo pipefail

ARCH="${1:-$(uname -m)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/vendor/hidapi-static/$ARCH"
SRC="$ROOT/vendor/hidapi-src"

if [[ ! -d "$SRC" ]]; then
  mkdir -p "$(dirname "$SRC")"
  git clone --depth 1 --branch hidapi-0.15.0 https://github.com/libusb/hidapi.git "$SRC"
fi

mkdir -p "$VENDOR/include/hidapi" "$VENDOR/lib"
OBJ="$VENDOR/hid.o"
LIB="$VENDOR/lib/libhidapi.a"

clang -arch "$ARCH" -O2 -c -I"$SRC/hidapi" "$SRC/mac/hid.c" -o "$OBJ"
ar rcs "$LIB" "$OBJ"
rm -f "$OBJ"

cp "$SRC/hidapi/hidapi.h" "$VENDOR/include/hidapi/"
cp "$SRC/mac/hidapi_darwin.h" "$VENDOR/include/hidapi/"

echo "Built $LIB ($ARCH)"
file "$LIB"
