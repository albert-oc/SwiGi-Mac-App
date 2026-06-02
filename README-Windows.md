# SwiGi for Windows 11

Native Windows system-tray app that synchronizes **Logitech Easy-Switch** between your Bluetooth keyboard and mouse — same behavior as the macOS app and [`swigi.py`](../swigi.py).

> **Branch `windows-11`:** .NET 8 tray application for **Windows 10/11** (x64).

## Requirements

- Windows 10 version 1809+ or **Windows 11** (x64)
- [.NET 8 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) (for framework-dependent builds)
- Logitech Bluetooth keyboard and mouse with HID++ **CHANGE_HOST** support
- **hidapi.dll** next to `SwiGi.exe` (see below)

## hidapi.dll

Download `hidapi.dll` for Windows x64 from [hidapi releases](https://github.com/libusb/hidapi/releases) and place it in one of:

- Same folder as `SwiGi.exe`
- `native/win-x64/hidapi.dll` in the repo (used when building from source)

Or run:

```powershell
.\scripts\fetch-hidapi-windows.ps1
python3 .\scripts\generate-app-icon-windows.py
```

## Download (pre-built binary)

| File | Platform |
|------|----------|
| [`SwiGi-1.0.0-Windows11-x64.zip`](releases/SwiGi-1.0.0-Windows11-x64.zip) | **Windows 10/11 (x64)** |

Unzip and run `SwiGi.exe`. Requires [.NET 8 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0).

## Build from source

```powershell
cd SwiGi.Win
dotnet build SwiGi.Win.sln -c Release
```

Output: `SwiGi.Win\SwiGi.Win\bin\Release\net8.0-windows10.0.17763.0\SwiGi.exe`

To rebuild the release zip locally:

```bash
./scripts/package-release-windows.sh
```

On Windows (PowerShell), after installing the .NET 8 SDK:

```powershell
.\scripts\package-release-windows.sh
```

### Publish (self-contained, optional)

```powershell
dotnet publish SwiGi.Win\SwiGi.Win.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

## Run

1. Pair your Logitech keyboard and mouse via Bluetooth.
2. Launch **SwiGi** (no main window — look for the tray icon near the clock).
3. Right-click the tray icon → **Start**.
4. Press **Easy-Switch** on the keyboard; the mouse should follow.

## Project layout

```
SwiGi.Win/
├── SwiGi.Win.sln
└── SwiGi.Win/
    ├── Hid/              # hidapi P/Invoke + HID++ protocol
    ├── SwiGiEngine.cs    # Background sync loop
    ├── TrayApplicationContext.cs
    └── Program.cs
```

## Branch overview

| Branch | Platform |
|--------|----------|
| `main` | macOS 26+ (Apple Silicon) |
| `macos-13` | macOS 13+ (Intel) |
| `windows-11` | Windows 10/11 (x64) |

## SmartScreen / antivirus

Unsigned builds may show Windows SmartScreen on first run. Use **More info → Run anyway**, or build and run locally from source.
