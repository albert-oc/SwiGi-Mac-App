#!/bin/bash
# Generate macOS AppIcon.appiconset (transparent edges, no white border).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$ROOT/scripts/generate-app-icon.py"
