gen-key32() {
	local format="base64"

	case "${1:-}" in
		--hex|-h)
			format="hex"
			;;
		--base64|-b|"")
			format="base64"
			;;
		*)
			echo "Usage: gen-key32 [--base64|--hex]" >&2
			return 1
			;;
	esac

	local openssl_cmd="${openssl_bin:-openssl}"
	if ! command -v "$openssl_cmd" >/dev/null 2>&1; then
		echo "Error: openssl not found." >&2
		return 1
	fi

	local key
	if [ "$format" = "hex" ]; then
		key=$("$openssl_cmd" rand -hex 32)
	else
		key=$("$openssl_cmd" rand -base64 32)
	fi

	if [ -n "$pbcopy_bin" ]; then
		printf "%s" "$key" | $pbcopy_bin
	elif [ -n "$xclip_bin" ]; then
		printf "%s" "$key" | $xclip_bin -selection clipboard
	elif [ -n "$xsel_bin" ]; then
		printf "%s" "$key" | $xsel_bin --clipboard --input
	elif [ -n "$wl_copy_bin" ]; then
		printf "%s" "$key" | $wl_copy_bin
	else
		echo "Error: no clipboard tool (pbcopy/xclip/xsel/wl-copy) found." >&2
		return 1
	fi

	echo "32-byte key ($format) copied to clipboard: $key"
}
