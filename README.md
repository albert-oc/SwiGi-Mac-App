# SwiGi for macOS

Native macOS menu bar app that synchronizes **Logitech Easy-Switch** across Bluetooth keyboard and mouse. When you press Easy-Switch on the keyboard, SwiGi forwards the same host switch to the mouse so both devices stay paired to the same machine.

This project is a Swift port of the original [`swigi.py`](swigi.py) script, packaged as a background menu bar application for **macOS 26+**.

## Requirements

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

### Option A — Using GitHub CLI (recommended)

```bash
# Install GitHub CLI if needed
brew install gh

# Authenticate (one-time)
gh auth login

# From this folder
cd /Users/albert.oc/Projects/SwiGi-Mac-App
git init
git add .
git commit -m "Initial commit: native macOS SwiGi menu bar app"

# Create repo on GitHub and push (choose public or private)
gh repo create SwiGi-Mac-App --source=. --remote=origin --push
```

Replace `SwiGi-Mac-App` with your preferred repository name.

### Option B — Using github.com (web UI)

1. Go to [github.com/new](https://github.com/new)
2. Set repository name (e.g. `SwiGi-Mac-App`), visibility, and **do not** initialize with README (this folder already has one)
3. Click **Create repository**
4. In Terminal, from this folder:

   ```bash
   cd /Users/albert.oc/Projects/SwiGi-Mac-App
   git init
   git add .
   git commit -m "Initial commit: native macOS SwiGi menu bar app"
   git branch -M main
   git remote add origin git@github.com:YOUR_USERNAME/SwiGi-Mac-App.git
   git push -u origin main
   ```

   Use the HTTPS URL instead of SSH if you prefer:

   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/SwiGi-Mac-App.git
   ```

### After linking

- `git remote -v` — confirm the remote URL
- `git push` — upload new commits
- In Xcode: set your **Development Team** under Signing & Capabilities before distributing the app

## Distribution note

Development builds link against Homebrew’s `libhidapi.dylib`. For a distributable `.app`, bundle `libhidapi.dylib` inside `SwiGi.app/Contents/Frameworks/` and adjust run-path search paths, or ship via Homebrew cask with a hidapi dependency.

## License

See the original `swigi.py` header for hidapi licensing. Add your preferred license for the Swift app wrapper if you plan to publish the repo.
