#!/bin/zsh
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build-unpacked"
OUT_ZIP="$ROOT/ChatExportSuite_v3_2.zip"

echo "=========================================="
echo " Chat Export Suite v3.2 – builder"
echo "=========================================="
echo "Root: $ROOT"

echo "[1/3] Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "[2/3] Copying files..."
cp "$ROOT/manifest.json" "$BUILD_DIR/"
cp "$ROOT/contentScript.js" "$BUILD_DIR/"
cp "$ROOT/export-print.js" "$BUILD_DIR/"
cp "$ROOT"/icon*.png "$BUILD_DIR/"
cp -R "$ROOT/popup" "$BUILD_DIR/"
cp -R "$ROOT/options" "$BUILD_DIR/"

echo "[3/3] Stripping extended attributes and creating ZIP..."
xattr -cr "$BUILD_DIR" 2>/dev/null || true

rm -f "$OUT_ZIP"
(
  cd "$BUILD_DIR"
  zip -r -X "$OUT_ZIP" . >/dev/null
)

echo "=========================================="
echo " Build complete."
echo " Unpacked: $BUILD_DIR"
echo " ZIP     : $OUT_ZIP"
echo "=========================================="
