#!/bin/sh

FUNCTIONS_DIR="${DEV_DIR:-}"
if [ -z "$FUNCTIONS_DIR" ]; then
  FUNCTIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
fi

if [ -d "$FUNCTIONS_DIR/functions" ]; then
  for f in "$FUNCTIONS_DIR"/functions/*.sh; do
    [ -f "$f" ] || continue
    . "$f"
  done
fi
