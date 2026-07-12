_web-fetch-parse-options() {
	while [ $# -gt 0 ]; do
		case "$1" in
			--xml) web_fetch_xml_mode=true ;;
			--no-cache) web_fetch_no_cache=true ;;
			--no-glow) web_fetch_no_glow=true ;;
			--max-lines)
				shift
				web_fetch_max_lines="${1:-}"
				case "$web_fetch_max_lines" in
					''|*[!0-9]*)
						echo "web-fetch: --max-lines must be a non-negative integer" >&2
						return 1
						;;
				esac
				;;
			--wait)
				shift
				web_fetch_wait_ms="${1:-}"
				case "$web_fetch_wait_ms" in
					''|*[!0-9]*)
						echo "web-fetch: --wait must be an integer (milliseconds)" >&2
						return 1
						;;
				esac
				;;
			-*)
				echo "web-fetch: unknown flag: $1" >&2
				echo "Usage: web-fetch <url> [--xml] [--wait <ms>] [--max-lines <n>] [--no-cache] [--no-glow]" >&2
				return 1
				;;
			*)
				if [ -z "$web_fetch_url" ]; then
					web_fetch_url="$1"
				else
					echo "web-fetch: unexpected argument: $1" >&2
					return 1
				fi
				;;
		esac
		shift
	done

	if [ -z "$web_fetch_url" ]; then
		echo "Usage: web-fetch <url> [--xml] [--wait <ms>] [--max-lines <n>] [--no-cache] [--no-glow]" >&2
		return 1
	fi
}

_web-fetch-get-content-type() {
	web_fetch_content_type="$($curl_bin -sI -L --max-time 10 "$web_fetch_url" 2>/dev/null | grep -i '^content-type:' | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/;.*//')"

	if [ -z "$web_fetch_content_type" ]; then
		echo "web-fetch: could not determine Content-Type for URL \"$web_fetch_url\"" >&2
		return 1
	fi

	case "$web_fetch_content_type" in
		text/html|application/xhtml+xml|text/xml|application/xml)
			web_fetch_mode=html
			;;
		application/json|text/plain)
			web_fetch_mode=raw
			;;
		*)
			echo "web-fetch: skipping (Content-Type: $web_fetch_content_type)" >&2
			return 1
			;;
	esac
}

_web-fetch-set-cache-paths() {
	web_fetch_cache_dir="$HOME/.cache/web-fetch"
	mkdir -p "$web_fetch_cache_dir" || return 1

	web_fetch_url_hash="$(printf '%s' "$web_fetch_url" | "$sha256sum_bin" | awk '{print $1}')"
	web_fetch_meta_cache="$web_fetch_cache_dir/$web_fetch_url_hash.meta"

	if [ "$web_fetch_mode" = "html" ]; then
		if $web_fetch_xml_mode; then
			web_fetch_content_cache="$web_fetch_cache_dir/$web_fetch_url_hash.xml"
		else
			web_fetch_content_cache="$web_fetch_cache_dir/$web_fetch_url_hash.markdown"
		fi
	else
		case "$web_fetch_content_type" in
			application/json) web_fetch_content_cache="$web_fetch_cache_dir/$web_fetch_url_hash.json" ;;
			text/plain) web_fetch_content_cache="$web_fetch_cache_dir/$web_fetch_url_hash.txt" ;;
		esac
	fi
}

_web-fetch-write-metadata() {
	printf 'fetched_at=%s\nurl=%s\ncontent_type=%s\n' \
		"$(date -Iseconds)" "$web_fetch_url" "$web_fetch_content_type" > "$web_fetch_meta_cache"
}

_web-fetch-use-cache() {
	local use_cache=false
	if ! $web_fetch_no_cache && [ -f "$web_fetch_content_cache" ] && [ -f "$web_fetch_meta_cache" ]; then
		local now cache_mtime
		now="$(date +%s)"
		cache_mtime="$(stat -f %m "$web_fetch_content_cache" 2>/dev/null || stat -c %Y "$web_fetch_content_cache" 2>/dev/null)"
		if [ -n "$cache_mtime" ] && [ "$((now - cache_mtime))" -lt 86400 ]; then
			use_cache=true
		fi
	fi

	if ! $use_cache; then
		return 1
	fi

	_web-fetch-output-cache
}

_web-fetch-output-cache() {
	if [ -n "$web_fetch_max_lines" ]; then
		local line_count
		line_count="$(awk 'END { print NR }' "$web_fetch_content_cache")"
		if [ "$line_count" -gt "$web_fetch_max_lines" ]; then
			head -n "$web_fetch_max_lines" "$web_fetch_content_cache"
			printf '\n[truncated: full content at %s]\n' "$web_fetch_content_cache"
			return 0
		fi
	fi

	if [ "$web_fetch_mode" = "html" ] && ! $web_fetch_no_glow && ! $web_fetch_xml_mode && [ -t 1 ] && [ -n "${glow_bin:-}" ] && [ -x "$glow_bin" ]; then
		"$glow_bin" - < "$web_fetch_content_cache"
	elif [ "$web_fetch_mode" = "raw" ] && [ "$web_fetch_content_type" = "application/json" ] && [ -t 1 ] && [ -n "${jq_bin:-}" ] && [ -x "$jq_bin" ]; then
		"$jq_bin" . "$web_fetch_content_cache"
	else
		cat "$web_fetch_content_cache"
	fi
}

_web-fetch-report-page-error() {
	local error_text
	error_text="$(cat "$1" 2>/dev/null)"
	local error_message
	case "$error_text" in
		*'404'*) error_message="404 Not Found" ;;
		*'403'*) error_message="403 Forbidden" ;;
		*'401'*) error_message="401 Unauthorized" ;;
		*'500'*) error_message="500 Internal Server Error" ;;
		*'502'*) error_message="502 Bad Gateway" ;;
		*'503'*) error_message="503 Service Unavailable" ;;
		*'ERR_TIMED_OUT'*|*'timeout'*|*'Timeout'*) error_message="Page timed out" ;;
		*'ERR_CONNECTION_REFUSED'*|*'connection refused'*) error_message="Page unavailable" ;;
		*'ERR_NAME_NOT_RESOLVED'*|*'Name or service not known'*) error_message="Page unavailable" ;;
		*'ERR_ABORTED'*|*'Target closed'*) error_message="Page crashed" ;;
		*) error_message="Page unavailable" ;;
	esac
	echo "web-fetch: $error_message" >&2
}

_web-fetch-fetch-html() {
	if [ -z "${shot_scraper_bin:-}" ] || [ ! -x "$shot_scraper_bin" ]; then
		echo "web-fetch: shot-scraper is not installed or not executable" >&2
		return 1
	fi
	if [ -z "${trafilatura_bin:-}" ] || [ ! -x "$trafilatura_bin" ]; then
		echo "web-fetch: trafilatura is not installed or not executable" >&2
		return 1
	fi

	local html_cache="$web_fetch_cache_dir/$web_fetch_url_hash.html"
	local ss_stderr
	ss_stderr="$(mktemp "$web_fetch_cache_dir/.stderr.XXXXXX")" || return 1

	"$shot_scraper_bin" html "$web_fetch_url" --wait "$web_fetch_wait_ms" --fail --silent > "$html_cache" 2> "$ss_stderr"
	local ss_exit=$?
	if [ $ss_exit -ne 0 ]; then
		_web-fetch-report-page-error "$ss_stderr"
		rm -f "$ss_stderr" "$html_cache"
		return 1
	fi
	rm -f "$ss_stderr"

	if [ ! -s "$html_cache" ]; then
		rm -f "$html_cache"
		echo "web-fetch: page returned empty content" >&2
		return 1
	fi

	local format_flag="--markdown"
	$web_fetch_xml_mode && format_flag="--xml"
	local traf_output
	traf_output="$($trafilatura_bin --no-comments --formatting --links --with-metadata -f "$format_flag" < "$html_cache" 2>&1)"
	if [ $? -ne 0 ]; then
		echo "web-fetch: trafilatura extraction failed" >&2
		return 1
	fi

	if [ -z "$traf_output" ]; then
		: > "$web_fetch_content_cache"
		_web-fetch-write-metadata
		echo "web-fetch: page extracted but produced no content" >&2
		return 1
	fi

	printf '%s\n' "$traf_output" > "$web_fetch_content_cache"
	_web-fetch-write-metadata
	_web-fetch-output-cache
}

_web-fetch-fetch-raw() {
	local raw_tmp
	raw_tmp="$(mktemp "$web_fetch_cache_dir/.raw.XXXXXX")" || return 1

	"$curl_bin" -sL --max-time 30 "$web_fetch_url" > "$raw_tmp" 2>&1
	local curl_exit=$?
	if [ $curl_exit -ne 0 ]; then
		rm -f "$raw_tmp"
		echo "web-fetch: fetch failed (curl exit $curl_exit)" >&2
		return 1
	fi

	if [ ! -s "$raw_tmp" ]; then
		rm -f "$raw_tmp"
		echo "web-fetch: response was empty" >&2
		return 1
	fi

	mv "$raw_tmp" "$web_fetch_content_cache" || return 1
	_web-fetch-write-metadata
	_web-fetch-output-cache
}

web-fetch() {
	web_fetch_url=""
	web_fetch_xml_mode=false
	web_fetch_wait_ms=2000
	web_fetch_no_cache=false
	web_fetch_no_glow=false
	web_fetch_max_lines=""

	_web-fetch-parse-options "$@" || return 1
	_web-fetch-get-content-type "$web_fetch_url" || return 1
	_web-fetch-set-cache-paths || return 1
	_web-fetch-use-cache && return 0

	if [ "$web_fetch_mode" = "html" ]; then
		_web-fetch-fetch-html || return 1
	else
		_web-fetch-fetch-raw || return 1
	fi
}

web-fetch-purge() {
	local cache_dir="$HOME/.cache/web-fetch"

	if [ ! -d "$cache_dir" ]; then
		echo "web-fetch-purge: cache directory does not exist"
		return 0
	fi

	local file_count size
	file_count="$(find "$cache_dir" -type f | wc -l | tr -d ' ')"
	size="$(du -sh "$cache_dir" 2>/dev/null | awk '{print $1}')"

	if [ "$file_count" -eq 0 ]; then
		echo "web-fetch-purge: cache is already empty"
		rm -rf "$cache_dir"
		return 0
	fi

	echo "Cache: $cache_dir"
	echo "Files: $file_count"
	echo "Size:  $size"
	echo ""

	if [ -n "${glow_bin:-}" ] && [ -x "$glow_bin" ] && [ -t 1 ]; then
		for meta in "$cache_dir"/*.meta; do
			[ -f "$meta" ] || continue
			grep '^url=' "$meta" | sed 's/^url=//'
		done | "$glow_bin" -
	else
		for meta in "$cache_dir"/*.meta; do
			[ -f "$meta" ] || continue
			grep '^url=' "$meta" | sed 's/^url=//'
		done
	fi

	echo ""
	printf "Type PURGE to clear all cached fetches: "

	local confirm
	IFS= read -r confirm

	if [ "$confirm" != "PURGE" ]; then
		echo "Aborted."
		return 1
	fi

	rm -rf "$cache_dir"
	echo "web-fetch-purge: cache cleared ($file_count files, $size)"
}
