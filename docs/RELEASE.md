# Release Guide

## Overview

This project ships as a standalone macOS app bundle plus distributable archives.

Current artifact outputs:

- `dist/LocalhostWatcher.app`
- `dist/LocalhostWatcher-1.0.dmg`
- `dist/LocalhostWatcher-1.0.zip`

## Local Build

Debug build:

```bash
swift build
```

Debug app bundle and launch:

```bash
./run-menubar.sh
```

Release binary:

```bash
swift build -c release
```

## Release Packaging Flow

The reliable release flow is:

1. Build the release binary with `swift build -c release`
2. Assemble a clean `.app` bundle from `.build/arm64-apple-macosx/release`
3. Copy the app icon and SwiftPM resource bundle into `Contents/Resources`
4. Sign the `.app` with `Developer ID Application`
5. Create a distributable `.dmg`
6. Sign the `.dmg`
7. Submit the `.dmg` for notarization
8. Staple the notarization ticket to the `.dmg`
9. Optionally zip and notarize the standalone `.app`

## Signing Identity

Use the local Developer ID Application certificate, not an Apple Development or Apple Distribution identity.

Expected identity format:

```text
Developer ID Application: <Name> (<Team ID>)
```

## Notarization Notes

- Notarize release builds, not debug builds.
- Debug builds may include attributes that Apple rejects for notarization.
- If notarization fails, fetch the detailed notarization log with `xcrun notarytool log <submission-id>`.

## Validation Commands

Inspect app signature:

```bash
codesign -dv --verbose=4 dist/LocalhostWatcher.app
```

Verify app signature:

```bash
codesign --verify --deep --strict --verbose=2 dist/LocalhostWatcher.app
```

Validate a stapled disk image:

```bash
xcrun stapler validate dist/LocalhostWatcher-1.0.dmg
```

Inspect disk image metadata:

```bash
hdiutil imageinfo dist/LocalhostWatcher-1.0.dmg
```

## Important Packaging Detail

This app depends on the SwiftPM-generated runtime resource directory:

```text
LocalhostWatcher_LocalhostWatcher.bundle
```

If that resource bundle is missing from `Contents/Resources`, the packaged app may launch incorrectly or fail to find its app icon resource at runtime.

## Recommended Distribution Artifact

The best end-user artifact is the notarized `.dmg`.

Use the `.zip` if you need to distribute the standalone app bundle outside the disk image flow.
