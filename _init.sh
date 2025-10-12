#!/bin/sh

ENABLED_MODULES=(dev git pkg)

SCRIPT_DIR=""
if [ -n "$BASH_VERSION" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "$ZSH_VERSION" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# always load core first
[ -f "$SCRIPT_DIR/core/_init.sh" ] && . "$SCRIPT_DIR/core/_init.sh"

# load each init files in subdirs
for module in "${ENABLED_MODULES[@]}"; do
  f="$SCRIPT_DIR/$module/_init.sh"
  [ -f "$f" ] && . "$f"
done