#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Scrubadub"
CLI_NAME="scrubadub"
BUNDLE_ID="${BUNDLE_ID:-com.stevenhaddix.scrubadub}"

cd "$ROOT_DIR"
source "$ROOT_DIR/version.env"

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

case "$CONFIGURATION" in
  debug|release) ;;
  *) fail "configuration must be debug or release" ;;
esac

ARCH_ARGS=()
if [[ "$CONFIGURATION" == "release" && "${UNIVERSAL:-1}" == "1" ]]; then
  ARCH_ARGS=(--arch arm64 --arch x86_64)
fi

log "==> Building ${APP_NAME} (${CONFIGURATION})"
swift build -c "$CONFIGURATION" "${ARCH_ARGS[@]}" --product "$APP_NAME"
BIN_DIR="$(swift build -c "$CONFIGURATION" "${ARCH_ARGS[@]}" --show-bin-path)"
APP_EXECUTABLE="$BIN_DIR/$APP_NAME"
RESOURCE_BUNDLE="$BIN_DIR/${APP_NAME}_${APP_NAME}.bundle"
STAGED_APP_EXECUTABLE="$ROOT_DIR/.build/${APP_NAME}-app-executable"
cp "$APP_EXECUTABLE" "$STAGED_APP_EXECUTABLE"

swift build -c "$CONFIGURATION" "${ARCH_ARGS[@]}" --product "$CLI_NAME"
CLI_EXECUTABLE="$BIN_DIR/$CLI_NAME"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
ZIP_PATH="$ROOT_DIR/dist/${APP_NAME}-${MARKETING_VERSION}.zip"
SHA_PATH="${ZIP_PATH}.sha256"

[[ -x "$STAGED_APP_EXECUTABLE" ]] || fail "missing app executable: $STAGED_APP_EXECUTABLE"
[[ -x "$CLI_EXECUTABLE" ]] || fail "missing CLI executable: $CLI_EXECUTABLE"

log "==> Creating app bundle: $APP_BUNDLE"
rm -rf "$APP_BUNDLE" "$ZIP_PATH" "$SHA_PATH"
mkdir -p \
  "$APP_BUNDLE/Contents/MacOS" \
  "$APP_BUNDLE/Contents/Helpers" \
  "$APP_BUNDLE/Contents/Resources"

cp "$STAGED_APP_EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$CLI_EXECUTABLE" "$APP_BUNDLE/Contents/Helpers/$CLI_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME" "$APP_BUNDLE/Contents/Helpers/$CLI_NAME"

if [[ -d "$RESOURCE_BUNDLE/Contents/Resources" ]]; then
  log "==> Installing SwiftPM resources"
  cp -R "$RESOURCE_BUNDLE/Contents/Resources/." "$APP_BUNDLE/Contents/Resources/"
fi

if [[ -f "$ROOT_DIR/Icon.icns" ]]; then
  log "==> Installing app icon"
  cp "$ROOT_DIR/Icon.icns" "$APP_BUNDLE/Contents/Resources/Icon.icns"
fi

log "==> Writing Info.plist"
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${MARKETING_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>MIT License.</string>
PLIST

if [[ -f "$ROOT_DIR/Icon.icns" ]]; then
  cat >> "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
  <key>CFBundleIconFile</key>
  <string>Icon</string>
PLIST
fi

cat >> "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
</dict>
</plist>
PLIST

log "==> Preparing for signing"
chmod -R u+w "$APP_BUNDLE"
xattr -cr "$APP_BUNDLE" || true
find "$APP_BUNDLE" -name '._*' -delete

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  log "==> Codesigning with ${CODESIGN_IDENTITY}"
  codesign --force --timestamp --options runtime --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE/Contents/Helpers/$CLI_NAME"
  codesign --force --timestamp --options runtime --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
elif [[ "${AD_HOC_SIGN:-1}" == "1" ]]; then
  log "==> Ad-hoc signing for local testing"
  codesign --force --sign - "$APP_BUNDLE/Contents/Helpers/$CLI_NAME"
  codesign --force --sign - "$APP_BUNDLE"
else
  log "==> Skipping codesign"
fi

if [[ "${NOTARIZE:-0}" == "1" ]]; then
  "$ROOT_DIR/Scripts/notarize_app.sh" "$APP_BUNDLE"
fi

log "==> Zipping release asset"
/usr/bin/ditto -c -k --keepParent --sequesterRsrc "$APP_BUNDLE" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$SHA_PATH"

log "==> Writing Homebrew cask"
"$ROOT_DIR/Scripts/write_homebrew_cask.sh" "$MARKETING_VERSION" "$(cut -d ' ' -f 1 "$SHA_PATH")"

log "Created:"
log "  $ZIP_PATH"
log "  $SHA_PATH"
log "  $ROOT_DIR/dist/homebrew/scrubadub.rb"
