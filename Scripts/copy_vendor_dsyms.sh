#!/bin/sh
# Copy third-party .dSYM bundles into the archive dSYM folder so Xcode / App Store Connect
# stop reporting "Upload Symbols Failed" for embedded frameworks (Veepoo/JL/ZipZap).
#
# Place matching dSYM folders in:  TamyrFlow/Vendor/dSYMs/
# See: Vendor/dSYMs/README.md and Docs/TESTFLIGHT_DSYM.md

# Never fail the Xcode build because of missing vendor symbols.
set +e
set -u

if [ -z "${DWARF_DSYM_FOLDER_PATH:-}" ]; then
  # Normal build / run — nothing to do
  exit 0
fi

VENDOR_DSYM_DIR="${SRCROOT}/Vendor/dSYMs"
if [ ! -d "$VENDOR_DSYM_DIR" ]; then
  echo "copy_vendor_dsyms: note — create ${VENDOR_DSYM_DIR} and add *.dSYM (see README there)."
  exit 0
fi

found=0
for dsym in "$VENDOR_DSYM_DIR"/*.dSYM; do
  [ -e "$dsym" ] || continue
  found=1
  name=$(basename "$dsym")
  rm -rf "${DWARF_DSYM_FOLDER_PATH:?}/${name}"
  cp -R "$dsym" "$DWARF_DSYM_FOLDER_PATH/" && echo "copy_vendor_dsyms: OK ${name}" || echo "copy_vendor_dsyms: FAILED ${name}"
done

if [ "$found" -eq 0 ]; then
  echo "copy_vendor_dsyms: note — no *.dSYM in ${VENDOR_DSYM_DIR}"
fi

exit 0
