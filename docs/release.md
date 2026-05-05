# Release Guide

Scrubadub ships as a signed macOS menu bar app with a bundled `scrubadub` CLI. Homebrew Cask is the primary install path; GitHub Releases are the source of truth for release assets.

## One-Time Setup

1. Use the public app repository `steven-haddix/scrub-a-dub`.
2. Use the tap repository `steven-haddix/homebrew-tap`.
3. Get a Developer ID Application certificate in Keychain Access.
4. Configure notarization credentials with either:
   - `xcrun notarytool store-credentials "Scrubadub Notary"`
   - App Store Connect API key environment variables.

## GitHub Actions Release

Use the manual **Release** workflow in GitHub Actions.

Required workflow inputs:

- `version`: release version without the leading `v`, for example `0.1.0`
- `build_number`: optional; defaults to the workflow run number
- `notarize`: keep enabled for public releases
- `publish_tap`: pushes the generated cask into `steven-haddix/homebrew-tap`

Required repository secrets for public notarized releases:

- `APPLE_DEVELOPER_ID_CERTIFICATE_BASE64`: base64-encoded `.p12` export of the Developer ID Application certificate
- `APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD`: password for that `.p12`
- `DEVELOPER_ID_APPLICATION`: full codesign identity, for example `Developer ID Application: Your Name (TEAMID)`
- `APP_STORE_CONNECT_API_KEY_P8`: App Store Connect API key contents
- `APP_STORE_CONNECT_KEY_ID`: App Store Connect key id
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect issuer id
- `HOMEBREW_TAP_TOKEN`: fine-grained token with write access to the tap repo, only needed when `publish_tap` is enabled

To create `APPLE_DEVELOPER_ID_CERTIFICATE_BASE64`:

```bash
base64 -i DeveloperIDApplication.p12 | pbcopy
```

The workflow runs tests, builds a universal app, signs/notarizes it, creates the GitHub release, uploads the zip/SHA assets, and optionally updates the Homebrew cask.

## Local Release

Update `version.env` and `CHANGELOG.md`, then run:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARIZE=1 \
NOTARY_PROFILE="Scrubadub Notary" \
Scripts/release.sh
```

This creates:

```text
dist/Scrubadub-<version>.zip
dist/Scrubadub-<version>.zip.sha256
dist/homebrew/scrubadub.rb
```

Publish the GitHub release:

```bash
PUBLISH=1 Scripts/release.sh
```

Then copy `dist/homebrew/scrubadub.rb` into `homebrew-tap/Casks/scrubadub.rb` and push the tap. The GitHub Actions release workflow does this automatically when `publish_tap` is enabled.

## User Install

After the tap is pushed, users install with:

```bash
brew install --cask steven-haddix/tap/scrubadub
```

The cask installs `Scrubadub.app` and symlinks the bundled CLI as `scrubadub`.
