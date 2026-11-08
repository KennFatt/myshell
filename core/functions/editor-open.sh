#!/bin/sh

# True when the editor behind $vscode_bin already has a running instance.
# macOS only: the main process lives at "<app>.app/Contents/MacOS/", while
# helpers live under "<app>.app/Contents/Frameworks/".
_vscode_running() {
	local cli link
	cli="${vscode_bin:-}"
	[ -n "$cli" ] && [ -n "${ps_bin:-}" ] || return 1

	while [ -L "$cli" ]; do
		link="$(readlink "$cli")"
		case "$link" in
		/*) cli="$link" ;;
		*) cli="$(dirname "$cli")/$link" ;;
		esac
	done

	case "$cli" in
	*/*.app/Contents/*)
		cli="${cli%%.app/Contents/*}.app"
		# pgrep -f silently misses long patterns on macOS; ps + fixed-string match is reliable.
		"$ps_bin" -Ao comm= | grep -F "$cli/Contents/MacOS/" >/dev/null 2>&1
		;;
	*)
		return 1
		;;
	esac
}

# Open a file in the running VSCode instance, otherwise in $EDITOR,
# otherwise print the path.
editor-open() {
	local file
	file="${1:-}"
	[ -n "$file" ] || return 1

	if _vscode_running; then
		"$vscode_bin" --reuse-window "$file"
		return $?
	fi

	if [ -n "${EDITOR:-}" ] && command -v "${EDITOR%% *}" >/dev/null 2>&1; then
		# zsh does not word-split unquoted parameters; ${=EDITOR} forces it.
		if [ -n "${ZSH_VERSION:-}" ]; then
			set -- ${=EDITOR}
		else
			set -- $EDITOR
		fi
		"$@" "$file"
		return $?
	fi

	printf '%s\n' "$file"
}
