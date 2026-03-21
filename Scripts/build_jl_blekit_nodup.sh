#!/bin/bash
# JL_BLEKit is a static archive that duplicates JL_Tools / JL_Timer / JLModel_File
# (same classes are in the dynamic JLDialUnit.framework) → objc duplicate-class warnings.
# This rebuilds a fat .a without JL_Tools.o and JLModel_File.o so the linker resolves
# those symbols from JLDialUnit instead.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/JL_BLEKit.framework/JL_BLEKit"
OUT="$ROOT/Vendor/JL_BLEKit_NoDup.a"
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC" >&2
  exit 1
fi

build_slice() {
  local arch="$1"
  local dir="$TMP/$arch"
  mkdir -p "$dir"
  lipo -thin "$arch" "$SRC" -output "$dir/lib.a"
  (cd "$dir" && ar -x lib.a)
  rm -f "$dir/lib.a"
  rm -f "$dir/JL_Tools.o" "$dir/JLModel_File.o"
  libtool -static -o "$dir/out.a" "$dir"/*.o
}

mkdir -p "$(dirname "$OUT")"
ARCHS=$(lipo -archs "$SRC")
if echo "$ARCHS" | grep -q arm64; then build_slice arm64; fi
if echo "$ARCHS" | grep -q armv7; then build_slice armv7; fi

if [[ -f "$TMP/arm64/out.a" && -f "$TMP/armv7/out.a" ]]; then
  lipo -create "$TMP/arm64/out.a" "$TMP/armv7/out.a" -output "$OUT"
elif [[ -f "$TMP/arm64/out.a" ]]; then
  cp "$TMP/arm64/out.a" "$OUT"
elif [[ -f "$TMP/armv7/out.a" ]]; then
  cp "$TMP/armv7/out.a" "$OUT"
else
  echo "No slices built" >&2
  exit 1
fi

echo "Wrote $OUT"
