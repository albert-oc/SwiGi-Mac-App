# SwiGi for macOS

Native macOS menu bar app that synchronizes **Logitech Easy-Switch** across Bluetooth keyboard and mouse. When you press Easy-Switch on the keyboard, SwiGi forwards the same host switch to the mouse so both devices stay paired to the same machine.

This project is a Swift port of the original [`swigi.py`](swigi.py) script, packaged as a background menu bar application for **macOS 26+**.

## macOS compatibility

| Version | Native app (`SwiGi.app`) | Python script (`swigi.py`) |
|---------|--------------------------|----------------------------|
| **macOS 26+** | Yes | Yes |
| macOS 13–25 | See MacOS-13 branch on this same repo | Yes |
| **macOS 12 (Monterey)** | **No** | Yes |

On macOS 12, use the Python script instead:

```bash
brew install hidapi python3
python3 swigi.py
```

To support older macOS with a native app would require lowering the deployment target.

## Download (pre-built binary)

A ready-to-run build is in [`releases/`](releases/):

| File | Platform |
|------|----------|
| [`SwiGi-1.0.0-macOS-arm64.zip`](releases/SwiGi-1.0.0-macOS-arm64.zip) | Apple Silicon (M1/M2/M3/M4), macOS 26+ |

**Install:**

1. Download and unzip the file.
2. Move `SwiGi.app` to `/Applications` (or anywhere you prefer).
3. First launch: if macOS blocks the app, open **System Settings → Privacy & Security** and click **Open Anyway** (the app is not notarized).
4. Click the SwiGi menu bar icon → **Start**.

## Requirements (build from source)

- macOS 26.0 or later
- Xcode 26+
- [hidapi](https://github.com/libusb/hidapi) (for development builds):

  ```bash
  brew install hidapi
  ```

- Logitech Bluetooth keyboard and mouse with HID++ **CHANGE_HOST** support (same devices supported by the Python script)

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
├── releases/             # Pre-built .zip downloads
├── scripts/
│   └── package-release.sh
├── SwiGi/
│   ├── SwiGi.xcodeproj   # Xcode project
│   ├── SwiGi/            # Swift app sources
│   └── CHIDAPI/          # hidapi module map for Swift
└── README.md
```

## GitHub repository setup

To create a new GitHub repo and link this folder:

### Prerequisites

1. A [GitHub account](https://github.com/signup)
2. Git installed (included with Xcode Command Line Tools)
3. Optional: [GitHub CLI](https://cli.github.com/) (`gh`) for creating repos from the terminal

## License

See the original `swigi.py` header for hidapi licensing.
