# Features

## Core Monitoring

- Scans local TCP listeners with `lsof`.
- Maps each listening port to the owning process.
- Resolves friendlier names for common JavaScript runtime processes.
- Tracks uptime for each detected process.

## Health Checks

- Sends lightweight `HEAD` requests to `http://localhost:<port>`.
- Classifies each service as `healthy`, `unhealthy`, or `unknown`.
- Refreshes health status automatically while the app is running.
- Surfaces unhealthy state in the menu bar icon summary and the app UI.

## Active View

The `Active` tab shows currently detected services.

For each service, the app shows:

- Process name
- Port
- Uptime
- Health status
- Whether it is saved for login relaunch

Available actions:

- Open the local URL
- Stop the process
- Save it for login relaunch
- Refresh the list

## Login View

The `Login` tab shows saved auto-start entries.

Each saved entry keeps:

- Port
- Display name
- Original launch command
- Working directory when available

Available actions:

- Review saved relaunch targets
- Remove saved entries
- See whether a saved service is currently active

## Menu Bar

The menu bar item shows:

- A symbol-style network icon
- The count of active detected services
- A tooltip/summary that mentions when attention is needed

Interaction model:

- Left click: open the popover
- Right click: open the context menu

## Context Menu Actions

- `Refresh Now`: rescans local services immediately
- `Kill All Unhealthy`: sends `TERM` to all currently unhealthy detected services
- `Show Active`: switches the popover to the active-services tab
- `Show Login`: switches the popover to the saved-login tab
- `Launch Watcher at Login`: toggles macOS launch-at-login for the app
- `About Localhost Watcher`
- `Quit Localhost Watcher`

## Auto Start

LocalhostWatcher supports two different startup behaviors:

- Launch the watcher itself at login using `SMAppService`
- Relaunch selected saved processes after the watcher starts

Saved process relaunch uses:

- The original launch command
- The captured working directory when available
- A one-time launch attempt per app session to avoid repeated respawns

## Packaging

The app includes:

- A custom app icon
- A menu bar style app bundle (`LSUIElement`)
- A packaged SwiftPM resource bundle used at runtime

Release distribution currently supports:

- `.app`
- `.dmg`
- `.zip`
