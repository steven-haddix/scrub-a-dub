#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-}"
BUILD_NUMBER="${2:-1}"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -n "$VERSION" ]] || fail "usage: Scripts/set_release_version.sh <version> [build_number]"

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}([.-][0-9A-Za-z.-]+)?$ ]]; then
  fail "version must look like 0.1.0 and must not include a leading v"
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  fail "build number must be numeric"
fi

cat > "$ROOT_DIR/version.env" <<EOF
MARKETING_VERSION=$VERSION
BUILD_NUMBER=$BUILD_NUMBER
EOF

cat > "$ROOT_DIR/Sources/ScrubadubCore/ScrubadubVersion.swift" <<EOF
public enum ScrubadubVersion {
    public static let current = "$VERSION"
}
EOF

printf 'Set Scrubadub release version to %s (%s)\n' "$VERSION" "$BUILD_NUMBER"
