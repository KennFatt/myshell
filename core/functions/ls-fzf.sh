ls-fzf() {
	[ -x "${lsd_bin:-}" ] || {
		echo "Error: lsd is not available." >&2
		return 1
	}
	[ -x "${fzf_bin:-}" ] || {
		echo "Error: fzf is not available." >&2
		return 1
	}
	command -v open >/dev/null 2>&1 || {
		echo "Error: open is not available." >&2
		return 1
	}

	local selected
	selected="$(
		"$lsd_bin" --color=never --icon=never --almost-all --oneline "$@" |
			"$fzf_bin" --prompt='ls> '
	)" || return

	[ -n "$selected" ] && open "$selected"
}
