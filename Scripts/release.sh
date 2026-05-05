#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "$ROOT_DIR/version.env"

swift test
"$ROOT_DIR/Scripts/package_app.sh" release

if [[ "${PUBLISH:-0}" == "1" ]]; then
  gh release create "v${MARKETING_VERSION}" \
    "dist/Scrubadub-${MARKETING_VERSION}.zip" \
    "dist/Scrubadub-${MARKETING_VERSION}.zip.sha256" \
    --title "v${MARKETING_VERSION}" \
    --notes-file CHANGELOG.md

  printf '\nCopy dist/homebrew/scrubadub.rb into your homebrew tap and push it.\n'
fi
