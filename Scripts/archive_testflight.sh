#!/usr/bin/env bash
# Archive TamyrFlow and upload to TestFlight (macOS + Xcode required).
# Usage (from repo root on Mac, signed into Xcode with team H6A22A3X2A):
#   ./Scripts/archive_testflight.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found — install Xcode from the App Store" >&2
  exit 1
fi

# Prefer full Xcode.app over bare Command Line Tools.
DEVELOPER_DIR_CURRENT="$(xcode-select -p 2>/dev/null || true)"
if [[ "${DEVELOPER_DIR_CURRENT}" != *"/Xcode.app/"* ]]; then
  if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    echo "==> Switching developer dir to /Applications/Xcode.app (needs sudo once)…"
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  else
    echo "error: full Xcode.app not found in /Applications." >&2
    echo "  Install Xcode, open it once, then run:" >&2
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
  fi
fi

# First-launch license acceptance (no-op if already accepted).
sudo xcodebuild -license accept >/dev/null 2>&1 || true
xcodebuild -runFirstLaunch >/dev/null 2>&1 || true

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED="${DERIVED:-$ROOT/build/testflight}"
ARCHIVE_PATH="$DERIVED/TamyrFlow.xcarchive"
EXPORT_DIR="$DERIVED/export"
EXPORT_PLIST="$DERIVED/ExportOptions.plist"

mkdir -p "$DERIVED"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

cat >"$EXPORT_PLIST" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>upload</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
PLIST

echo "==> Archiving TamyrFlow ($CONFIGURATION)…"
xcodebuild \
  -project TamyrFlow.xcodeproj \
  -scheme TamyrFlow \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  clean archive

echo "==> Exporting + uploading to App Store Connect / TestFlight…"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates

echo "==> Done. Check App Store Connect → TestFlight (processing often takes 5–20 min)."
