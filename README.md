# LocalhostWatcher

LocalhostWatcher is a macOS menu bar app that keeps your localhost apps visible, healthy, and easy to reopen.

It discovers active services on `localhost`, shows which ones actually respond, lets you open or stop them quickly, and can relaunch selected apps automatically after login.

## Get the App

- [Website](https://akakika.com/localhostwatcher/)
- [Download DMG](https://github.com/dot-RealityTest/LocalhostWatcher/releases/download/v1.0/LocalhostWatcher-1.0.dmg)
- [Release Notes](https://github.com/dot-RealityTest/LocalhostWatcher/releases/tag/v1.0)

## What It Does

- Lives quietly in the macOS menu bar as a lightweight utility.
- Detects active localhost apps and the process behind each port.
- Checks whether each detected service responds on `http://localhost:<port>`.
- Shows unhealthy services in both the menu bar state and the app popover.
- Lets you open, stop, or clean up services quickly.
- Saves selected apps so they can be relaunched automatically after login.
- Supports launch-at-login for the watcher itself.

## Main Views

- `Active`: the localhost apps currently running on your Mac.
- `Login`: the saved apps you want back after login.

## Menu Bar Behavior

- Left click opens the main popover.
- Right click opens the context menu.

Context menu actions:

- `Refresh Now`
- `Kill All Unhealthy`
- `Show Active`
- `Show Login`
- `Launch Watcher at Login`
- `About Localhost Watcher`
- `Quit Localhost Watcher`

## Requirements

- macOS 14+
- Xcode command line tools / Swift 5.9+

## Build From Source

Build:

```bash
swift build
```

Run tests:

```bash
swift test
```

Launch the app bundle in development:

```bash
./run-menubar.sh
```

Stop the running menu bar app:

```bash
./stop-menubar.sh
```

## Packaging

The project is a Swift Package, but it is packaged into a standalone `.app` bundle by `run-menubar.sh`.

For release packaging, signing, notarization, and disk images, see [docs/RELEASE.md](docs/RELEASE.md).

## Docs

- [Landing Page](docs/index.html)
- [Features](docs/FEATURES.md)
- [Release Guide](docs/RELEASE.md)
