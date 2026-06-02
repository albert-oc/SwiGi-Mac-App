# Download hidapi.dll for Windows x64 into native/win-x64/
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $Root "native\win-x64"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$Version = "0.15.0"
$ZipUrl = "https://github.com/libusb/hidapi/archive/refs/tags/hidapi-$Version.zip"
$TempZip = Join-Path $env:TEMP "hidapi-$Version.zip"
$TempDir = Join-Path $env:TEMP "hidapi-src-$Version"

Write-Host "Downloading hidapi $Version..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
Expand-Archive -Path $TempZip -DestinationPath $env:TEMP -Force
$SrcRoot = Get-ChildItem (Join-Path $env:TEMP "hidapi-hidapi-*") | Select-Object -First 1

# Pre-built DLLs are in GitHub release assets; clone and build with MSVC if missing
$Prebuilt = Join-Path $SrcRoot.FullName "windows\hidapi.dll"
if (Test-Path $Prebuilt) {
    Copy-Item $Prebuilt (Join-Path $OutDir "hidapi.dll")
} else {
    Write-Host "No prebuilt DLL in source tree. Download from:"
    Write-Host "  https://github.com/libusb/hidapi/releases/tag/hidapi-$Version"
    Write-Host "Place hidapi.dll in: $OutDir"
    exit 1
}

Write-Host "Installed: $(Join-Path $OutDir 'hidapi.dll')"
