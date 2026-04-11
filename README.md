# LocalhostWatcher

LocalhostWatcher is a macOS menu bar app for monitoring local development servers.

It discovers TCP listeners on `localhost`, shows health status, lets you open or stop processes quickly, and can relaunch selected apps automatically after login.

## What It Does

- Lives in the macOS menu bar as a lightweight utility.
- Detects active localhost servers and the process behind each port.
- Checks whether each detected service responds on `http://localhost:<port>`.
- Shows unhealthy services in both the menu bar state and the popover UI.
- Lets you stop individual services or kill all unhealthy services from the menu.
- Saves launchable services so they can be relaunched automatically on login.
- Supports launch-at-login for the watcher itself.

## Main Views

- `Active`: currently detected localhost listeners.
- `Login`: saved processes that should be relaunched after login.

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

## Development

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
