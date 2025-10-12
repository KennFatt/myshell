#!/bin/sh

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

# [ -f "$PKG_DIR/apt.sh" ] && . "$PKG_DIR/apt.sh"
[ -f "$PKG_DIR/brew.sh" ] && . "$PKG_DIR/brew.sh"
# [ -f "$PKG_DIR/dnf.sh" ] && . "$PKG_DIR/dnf.sh"
# [ -f "$PKG_DIR/pacman.sh" ] && . "$PKG_DIR/pacman.sh"