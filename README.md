# SwiGi for macOS

Native macOS menu bar app that synchronizes **Logitech Easy-Switch** across Bluetooth keyboard and mouse. When you press Easy-Switch on the keyboard, SwiGi forwards the same host switch to the mouse so both devices stay paired to the same machine.

This project is a Swift port of the original [`swigi.py`](swigi.py) script, packaged as a background menu bar application for **macOS 13+** (Ventura and later).

> **Branch `macos-13`:** Intel (x86_64) build for **macOS 13+**. Use **`main`** for Apple Silicon on macOS 26+.

## macOS compatibility

**macOS 13 (Ventura)** runs on both **Intel** and **Apple Silicon** Macs. This branch ships a native app for **Intel Macs (x86_64)** on macOS 13 and later.

| Version | Intel Mac (`x86_64`) | Apple Silicon (`arm64`) | Python script |
|---------|----------------------|-------------------------|---------------|
| **macOS 26+** | — | Yes (`main` branch) | Yes |
| **macOS 13–25** | **Yes** (this branch) | Use `main` if on macOS 26+, or `swigi.py` | Yes |
| **macOS 12 (Monterey)** | No | No | Yes |

macOS 12 is not supported by the native app. On Monterey, use the Python script:

```bash
brew install hidapi python3
python3 swigi.py
```

## Download (pre-built binary)

A ready-to-run **Intel** build is in [`releases/`](releases/):

| File | Platform |
|------|----------|
| [`SwiGi-1.1.1-macOS13-intel.zip`](releases/SwiGi-1.1.1-macOS13-intel.zip) | **Intel Mac (x86_64)**, macOS 13+ |

**Install:**

1. Download and unzip the file.
2. Move `SwiGi.app` to `/Applications` (or anywhere you prefer).
3. Open `SwiGi.app` (allow in **System Settings → Privacy & Security** if macOS blocks an unsigned app).
4. Look for the **SwiGi icon in the menu bar** (top-right) — there is no Dock icon.
5. Click the icon → **Start**.

## Requirements (build from source)

- **Intel Mac** or Apple Silicon Mac with Rosetta (to cross-compile x86_64)
- macOS 13.0 or later (to run the built app)
- Xcode 15+
- Logitech Bluetooth keyboard and mouse with HID++ **CHANGE_HOST** support (same devices supported by the Python script)

`libhidapi` is linked statically (`vendor/hidapi-static/`); Homebrew hidapi is not required.

## Build & Run

1. Open the Xcode project:

   ```bash
   open SwiGi/SwiGi.xcodeproj
   ```

2. Select the **SwiGi** scheme and press **Run** (⌘R).

3. Click the SwiGi icon in the menu bar, then **Start**.

The app runs as a menu bar agent (`LSUIElement`) with no Dock icon. Use **Quit SwiGi** from the menu to exit.

## How it works

1. Discovers Logitech keyboard and mouse over Bluetooth via hidapi
2. Listens for Easy-Switch (`CHANGE_HOST`) notifications from the keyboard
3. Sends the matching `CHANGE_HOST` command to the mouse
4. Reconnects automatically if a device drops off Bluetooth

## Project layout

```
SwiGi-Mac-App/
├── swigi.py              # Original Python reference implementation
├── assets/               # Source app icon (1024×1024)
├── releases/             # Pre-built .zip downloads
├── scripts/
│   ├── build-hidapi-static.sh
│   ├── generate-app-icon.sh
│   └── package-release.sh
├── SwiGi/
│   ├── SwiGi.xcodeproj   # Xcode project
│   ├── SwiGi/            # Swift app sources
│   └── CHIDAPI/          # hidapi module map for Swift
└── README.md
```

## License

See the original `swigi.py` header for hidapi licensing.
