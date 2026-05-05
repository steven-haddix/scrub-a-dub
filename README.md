# scrub-a-dub 🦆

A macOS menu-bar utility that strips terminal-width padding from Claude Code CLI output (and any other right-padded terminal text). Paste in, cleaned text auto-replaces your clipboard, paste out.

## Install

Homebrew Cask is the recommended install path:

```bash
brew install --cask steven-haddix/tap/scrubadub
```

Direct downloads are available from the latest GitHub release.

The cask installs the menu bar app and symlinks the CLI as `scrubadub`:

```bash
pbpaste | scrubadub | pbcopy
```

## Quick start

```bash
swift build
swift run Scrubadub        # launches the menu bar app
swift test                 # runs the cleaner test suite
```

CLI usage (no menu bar app, just the cleaner):

```bash
pbpaste | swift run scrubadub | pbcopy
```

## What gets cleaned

Always:

- Trailing whitespace on every line.

Default-on (toggleable):

- ANSI escape codes (`\x1B[…m` color sequences, OSC, charset switches).
- Outer blank lines (leading/trailing empty lines of the paste).
- Space-only lines collapse to true empty lines (this is implicit once trailing whitespace is stripped).

Default-off (toggleable in Settings):

- Collapse 3+ consecutive blank lines to 1.
- Strip box-drawing borders (`╭╮╰╯─│║`) and leading gutter chars.

## Project layout

```
Sources/
  ScrubadubCore/   # Pure cleaning library (no I/O, no UI)
  Scrubadub/       # SwiftUI menu-bar app
  scrubadub-cli/   # stdin → cleaned stdout
Tests/
  ScrubadubCoreTests/
```

`ScrubadubCore.Cleaner.clean(input, opts) -> CleanResult` is a pure function. Both the app and the CLI call it.

## Release

Release packaging lives in `Scripts/` and the manual GitHub Actions release flow is documented in `docs/release.md`.

```bash
Scripts/package_app.sh release
```

That creates a zipped `.app`, a SHA256 file, and a generated Homebrew cask at `dist/homebrew/scrubadub.rb`.
