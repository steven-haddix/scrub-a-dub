# scrub-a-dub 🦆

A macOS menu-bar utility that strips terminal-width padding from Claude Code CLI output (and any other right-padded terminal text). Paste in, cleaned text auto-replaces your clipboard, paste out.

## Quick start

```bash
swift build
swift run Scrubadub        # launches the menu bar app
swift test                 # runs the cleaner test suite
```

CLI usage (no menu bar app, just the cleaner):

```bash
pbpaste | swift run scrubadub-cli | pbcopy
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
