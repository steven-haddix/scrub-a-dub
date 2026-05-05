#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE="${1:-}"
[[ -n "$APP_BUNDLE" ]] || {
  printf 'Usage: %s path/to/Scrubadub.app\n' "$0" >&2
  exit 1
}
[[ -d "$APP_BUNDLE" ]] || {
  printf 'ERROR: app bundle not found: %s\n' "$APP_BUNDLE" >&2
  exit 1
}

TMP_ZIP="$(mktemp -t scrubadub-notary).zip"
trap 'rm -f "$TMP_ZIP"' EXIT

/usr/bin/ditto -c -k --keepParent --sequesterRsrc "$APP_BUNDLE" "$TMP_ZIP"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$TMP_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
elif [[ -n "${APP_STORE_CONNECT_API_KEY_P8:-}" && -n "${APP_STORE_CONNECT_KEY_ID:-}" ]]; then
  API_KEY_FILE="$(mktemp -t scrubadub-notary-key).p8"
  trap 'rm -f "$TMP_ZIP" "$API_KEY_FILE"' EXIT
  printf '%s' "$APP_STORE_CONNECT_API_KEY_P8" | sed 's/\\n/\n/g' > "$API_KEY_FILE"
  args=(--key "$API_KEY_FILE" --key-id "$APP_STORE_CONNECT_KEY_ID")
  if [[ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
    args+=(--issuer "$APP_STORE_CONNECT_ISSUER_ID")
  fi
  xcrun notarytool submit "$TMP_ZIP" "${args[@]}" --wait
else
  printf 'ERROR: set NOTARY_PROFILE or APP_STORE_CONNECT_API_KEY_P8/KEY_ID for notarization.\n' >&2
  exit 1
fi

xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"
spctl --assess --type exec --verbose "$APP_BUNDLE"
