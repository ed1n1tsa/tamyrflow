#!/usr/bin/env bash
# Archive TamyrFlow and upload to TestFlight (macOS + Xcode required).
# Usage (from repo root on Mac, signed into Xcode with team H6A22A3X2A):
#   ./Scripts/archive_testflight.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found — run this on a Mac with Xcode" >&2
  exit 1
fi

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED="${DERIVED:-$ROOT/build/testflight}"
ARCHIVE_PATH="$DERIVED/TamyrFlow.xcarchive"
EXPORT_DIR="$DERIVED/export"
EXPORT_PLIST="$DERIVED/ExportOptions.plist"

mkdir -p "$DERIVED" "$EXPORT_DIR"
rm -rf "$ARCHIVE_PATH"
rm -rf "$EXPORT_DIR"
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
