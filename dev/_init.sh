#!/bin/sh

DEV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

[ -f "$DEV_DIR/aliases.sh" ] && . "$DEV_DIR/aliases.sh"
[ -f "$DEV_DIR/functions.sh" ] && . "$DEV_DIR/functions.sh"
[ -f "$DEV_DIR/exports.sh" ] && . "$DEV_DIR/exports.sh"