#!/bin/sh

CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

[ -f "$CORE_DIR/secrets.sh" ] && . "$CORE_DIR/secrets.sh"
[ -f "$CORE_DIR/dependencies.sh" ] && . "$CORE_DIR/dependencies.sh"
[ -f "$CORE_DIR/paths.sh" ] && . "$CORE_DIR/paths.sh"
[ -f "$CORE_DIR/aliases.sh" ] && . "$CORE_DIR/aliases.sh"
[ -f "$CORE_DIR/functions.sh" ] && . "$CORE_DIR/functions.sh"
[ -f "$CORE_DIR/exports.sh" ] && . "$CORE_DIR/exports.sh"