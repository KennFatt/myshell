PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source_if_exists() {
	[ -f "$1" ] && . "$1"
}

source_if_exists "$PKG_DIR/container.sh"

if command -v apt-get >/dev/null 2>&1; then
	source_if_exists "$PKG_DIR/apt.sh"
elif command -v brew >/dev/null 2>&1; then
	source_if_exists "$PKG_DIR/brew.sh"
elif command -v dnf >/dev/null 2>&1; then
	source_if_exists "$PKG_DIR/dnf.sh"
elif command -v pacman >/dev/null 2>&1; then
	source_if_exists "$PKG_DIR/pacman.sh"
else
	printf 'No supported package manager found.\n' >&2
	return 1 2>/dev/null || exit 1
fi