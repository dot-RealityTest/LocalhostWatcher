#!/bin/bash
set -euo pipefail

APP_NAME="LocalhostWatcher"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  pkill -x "$APP_NAME"
  echo "Stopped $APP_NAME."
else
  echo "$APP_NAME is not running."
fi
