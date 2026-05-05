#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
SHA256="${2:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${GITHUB_REPOSITORY:-steven-haddix/scrub-a-dub}"
OUT_DIR="$ROOT_DIR/dist/homebrew"
OUT_FILE="$OUT_DIR/scrubadub.rb"

[[ -n "$VERSION" ]] || {
  printf 'Usage: %s VERSION SHA256\n' "$0" >&2
  exit 1
}
[[ -n "$SHA256" ]] || {
  printf 'Usage: %s VERSION SHA256\n' "$0" >&2
  exit 1
}

mkdir -p "$OUT_DIR"

cat > "$OUT_FILE" <<RUBY
cask "scrubadub" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/$REPO/releases/download/v#{version}/Scrubadub-#{version}.zip"
  name "Scrubadub"
  desc "Menu bar app and CLI for cleaning padded LLM terminal output"
  homepage "https://github.com/$REPO"

  app "Scrubadub.app"
  binary "#{appdir}/Scrubadub.app/Contents/Helpers/scrubadub"

  zap trash: [
    "~/Library/Application Support/Scrubadub",
    "~/Library/Preferences/com.stevenhaddix.scrubadub.plist",
  ]
end
RUBY

printf '%s\n' "$OUT_FILE"
