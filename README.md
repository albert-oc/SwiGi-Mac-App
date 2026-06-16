# SwiGi for macOS

Native macOS menu bar app that synchronizes **Logitech Easy-Switch** across Bluetooth keyboard and mouse. When you press Easy-Switch on the keyboard, SwiGi forwards the same host switch to the mouse so both devices stay paired to the same machine.

This project is a Swift port of the original [`swigi.py`](swigi.py) script, packaged as a background menu bar application for **macOS 26+**.

> **Other platforms:** branch **`windows-11`** (Windows tray app) · branch **`macos-13`** (Intel Mac, macOS 13+)

## macOS compatibility

| Version | Native app (`SwiGi.app`) | Python script (`swigi.py`) |
|---------|--------------------------|----------------------------|
| **macOS 26+** | Yes | Yes |
| macOS 13–25 | See **`macos-13`** branch | Yes |
| **macOS 12 (Monterey)** | **No** | Yes |

On macOS 12, use the Python script instead:

```bash
brew install hidapi python3
python3 swigi.py
```

## Download (pre-built binary)

A ready-to-run build is in [`releases/`](releases/):

| File | Platform |
|------|----------|
| [`SwiGi-1.1.1-macOS26-arm64.zip`](releases/SwiGi-1.1.1-macOS26-arm64.zip) | Apple Silicon (M1/M2/M3/M4), macOS 26+ |

**Install:**

1. Download and unzip the file.
2. Move `SwiGi.app` to `/Applications` (or anywhere you prefer).
3. Open `SwiGi.app` (allow in **System Settings → Privacy & Security** if macOS blocks an unsigned app).
4. Look for the **SwiGi icon in the menu bar** (top-right) — there is no Dock icon.
5. Click the icon → **Start**.

## Troubleshooting (pre-built binary)

### “Cannot verify” or malware warning

SwiGi is not notarized by Apple. If macOS says it **cannot verify** the developer or warns that the software **may contain malware**, remove the download quarantine in Terminal (adjust the path if you did not install to `/Applications`):

```bash
xattr -cr /Applications/SwiGi.app
```

Then open `SwiGi.app` again. If macOS still blocks it, right-click the app → **Open** → **Open**.

### App seems to do nothing when opened

SwiGi runs in the **menu bar only** (no Dock icon). Look for the SwiGi icon at the top-right of the screen, click it, then choose **Start**.

## Requirements (build from source)

- macOS 26.0 or later
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
