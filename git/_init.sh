#!/bin/sh

GIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

[ -f "$GIT_DIR/aliases.sh" ] && . "$GIT_DIR/aliases.sh"
[ -f "$GIT_DIR/functions.sh" ] && . "$GIT_DIR/functions.sh"