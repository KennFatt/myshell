#!/bin/sh

prompts() {
	local target_dir selected files
	target_dir="$PWD/.prompts-log"

	while [ "$#" -gt 0 ]; do
		case "$1" in
		--dir)
			if [ "$#" -lt 2 ]; then
				echo "Usage: prompts [--dir <directory>]"
				return 1
			fi
			target_dir="$2"
			shift 2
			;;
		*)
			echo "Unknown argument: $1"
			echo "Usage: prompts [--dir <directory>]"
			return 1
			;;
		esac
	done

	mkdir -p "$target_dir" || return 1

	files="$(find "$target_dir" -type f -name '*.prompt.md' | sort -r)"

	if [ -z "$files" ]; then
		echo "No prompts found in: $target_dir"
		return 0
	fi

	if [ -n "${fzf_bin:-}" ] && [ -x "$fzf_bin" ]; then
		selected="$(printf '%s\n' "$files" | "$fzf_bin" --prompt="Select prompt: ")"
		[ -n "$selected" ] || return 0
	else
		printf '%s\n' "$files"
		return 0
	fi

	if [ -n "${EDITOR:-}" ] && command -v "$EDITOR" >/dev/null 2>&1; then
		"$EDITOR" "$selected"
	else
		printf '%s\n' "$selected"
	fi
}

prompts-create() {
	local target_dir title slug timestamp prompt_dir prompt_file
	target_dir="$PWD/.prompts-log"
	title=""

	while [ "$#" -gt 0 ]; do
		case "$1" in
		--dir)
			if [ "$#" -lt 2 ]; then
				echo "Usage: prompts-create <prompt-title> [--dir <directory>]"
				return 1
			fi
			target_dir="$2"
			shift 2
			;;
		*)
			if [ -n "$title" ]; then
				echo "Only one prompt title is accepted. Quote titles containing spaces."
				return 1
			fi
			title="$1"
			shift
			;;
		esac
	done

	if [ -z "$title" ]; then
		echo "Usage: prompts-create <prompt-title> [--dir <directory>]"
		return 1
	fi

	slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g; s/-\{1,\}/-/g; s/^-//; s/-$//')"
	[ -n "$slug" ] || slug="prompt"

	mkdir -p "$target_dir" || return 1

	if [ -n "${python3_bin:-}" ] && [ -x "$python3_bin" ]; then
		timestamp="$("$python3_bin" -c 'import time; print(time.time_ns() // 1_000_000)')"
	else
		timestamp="$(date +%s)000"
	fi
	prompt_dir="$target_dir/$timestamp-$slug"
	prompt_file="$prompt_dir/$slug.prompt.md"

	mkdir -p "$prompt_dir" || return 1

	if ! printf '# %s\n\n' "$title" > "$prompt_file"; then
		echo "Could not create prompt: $prompt_file"
		return 1
	fi

	if [ -n "${EDITOR:-}" ] && command -v "$EDITOR" >/dev/null 2>&1; then
		"$EDITOR" "$prompt_file"
	else
		printf '%s\n' "$prompt_file"
	fi
}

prompts-status() {
	local target_dir files count first latest
	target_dir="$PWD/.prompts-log"

	while [ "$#" -gt 0 ]; do
		case "$1" in
		--dir)
			if [ "$#" -lt 2 ]; then
				echo "Usage: prompts-status [--dir <directory>]"
				return 1
			fi
			target_dir="$2"
			shift 2
			;;
		*)
			echo "Unknown argument: $1"
			echo "Usage: prompts-status [--dir <directory>]"
			return 1
			;;
		esac
	done

	if [ ! -d "$target_dir" ]; then
		echo "Prompts log directory does not exist: $target_dir"
		return 1
	fi

	files="$(find "$target_dir" -type d | while IFS= read -r file; do
		[ "$(dirname "$file")" = "$target_dir" ] && basename "$file"
	done | sort)"
	if [ -n "$files" ]; then
		count="$(printf '%s\n' "$files" | wc -l | tr -d ' ')"
	else
		count=0
	fi

	echo "Prompts log status"
	echo "Directory: $target_dir"
	echo "Prompts: $count"

	if [ "$count" -eq 0 ]; then
		echo "First prompt: none"
		echo "Latest prompt: none"
		return 0
	fi

	first="$(printf '%s\n' "$files" | head -n 1)"
	latest="$(printf '%s\n' "$files" | tail -n 1)"
	echo "First prompt: $first"
	echo "Latest prompt: $latest"
}
