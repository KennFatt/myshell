_web-fetch-parse-options() {
	while [ $# -gt 0 ]; do
		case "$1" in
		--xml) web_fetch_xml_mode=true ;;
		--no-cache) web_fetch_no_cache=true ;;
		--no-glow) web_fetch_no_glow=true ;;
		--jobs)
			shift
			web_fetch_jobs="${1:-}"
			case "$web_fetch_jobs" in
			'' | *[!0-9]* | 0)
				echo "web-fetch: --jobs must be a positive integer" >&2
				return 1
				;;
			esac
			;;
		--max-lines)
			shift
			web_fetch_max_lines="${1:-}"
			case "$web_fetch_max_lines" in
			'' | *[!0-9]*)
				echo "web-fetch: --max-lines must be a non-negative integer" >&2
				return 1
				;;
			esac
			;;
		--wait)
			shift
			web_fetch_wait_ms="${1:-}"
			case "$web_fetch_wait_ms" in
			'' | *[!0-9]*)
				echo "web-fetch: --wait must be an integer (milliseconds)" >&2
				return 1
				;;
			esac
			;;
		-*)
			echo "web-fetch: unknown flag: $1" >&2
			echo "Usage: web-fetch [options] <url> [url ...]" >&2
			return 1
			;;
		*)
			printf '%s\n' "$1" >>"$web_fetch_urls_file" || return 1
			web_fetch_url_count=$((web_fetch_url_count + 1))
			;;
		esac
		shift
	done

	if [ "$web_fetch_url_count" -eq 0 ]; then
		echo "Usage: web-fetch [options] <url> [url ...]" >&2
		return 1
	fi
}

_web-fetch-http-status-name() {
	case "$1" in
	200) printf '%s\n' 'OK' ;;
	201) printf '%s\n' 'Created' ;;
	204) printf '%s\n' 'No Content' ;;
	301) printf '%s\n' 'Moved Permanently' ;;
	302) printf '%s\n' 'Found' ;;
	304) printf '%s\n' 'Not Modified' ;;
	400) printf '%s\n' 'Bad Request' ;;
	401) printf '%s\n' 'Unauthorized' ;;
	403) printf '%s\n' 'Forbidden' ;;
	404) printf '%s\n' 'Not Found' ;;
	405) printf '%s\n' 'Method Not Allowed' ;;
	408) printf '%s\n' 'Request Timeout' ;;
	409) printf '%s\n' 'Conflict' ;;
	429) printf '%s\n' 'Too Many Requests' ;;
	500) printf '%s\n' 'Internal Server Error' ;;
	501) printf '%s\n' 'Not Implemented' ;;
	502) printf '%s\n' 'Bad Gateway' ;;
	503) printf '%s\n' 'Service Unavailable' ;;
	504) printf '%s\n' 'Gateway Timeout' ;;
	2??) printf '%s\n' 'Success' ;;
	3??) printf '%s\n' 'Redirection' ;;
	4??) printf '%s\n' 'Client Error' ;;
	5??) printf '%s\n' 'Server Error' ;;
	*) printf '%s\n' 'Unknown Status' ;;
	esac
}

_web-fetch-report-http-status() {
	echo "web-fetch: HTTP $1 $(_web-fetch-http-status-name "$1") for URL \"$web_fetch_url\"" >&2
}

_web-fetch-clean-probe() {
	if [ -n "${web_fetch_probe_body:-}" ]; then
		rm -f "$web_fetch_probe_body"
	fi
	web_fetch_probe_body=""
}

_web-fetch-probe() {
	local probe_headers probe_body probe_status probe_stderr
	local curl_exit curl_error
	probe_headers="$(mktemp "$web_fetch_cache_dir/.headers.XXXXXX")" || return 1
	probe_body="$(mktemp "$web_fetch_cache_dir/.probe.XXXXXX")" || {
		rm -f "$probe_headers"
		return 1
	}
	probe_status="$(mktemp "$web_fetch_cache_dir/.status.XXXXXX")" || {
		rm -f "$probe_headers" "$probe_body"
		return 1
	}
	probe_stderr="$(mktemp "$web_fetch_cache_dir/.stderr.XXXXXX")" || {
		rm -f "$probe_headers" "$probe_body" "$probe_status"
		return 1
	}

	"$curl_bin" -sS -L --max-time 30 \
		-A "$web_fetch_user_agent" \
		-D "$probe_headers" \
		-o "$probe_body" \
		-w '%{http_code}' \
		"$web_fetch_url" >"$probe_status" 2>"$probe_stderr"
	curl_exit=$?
	web_fetch_http_status="$(cat "$probe_status")"
	web_fetch_probe_body="$probe_body"

	if [ $curl_exit -ne 0 ]; then
		curl_error="$(tr '\n' ' ' <"$probe_stderr")"
		rm -f "$probe_headers" "$probe_status" "$probe_stderr"
		_web-fetch-clean-probe
		echo "web-fetch: request failed (curl exit $curl_exit; HTTP ${web_fetch_http_status:-000}; ${curl_error:-transport error})" >&2
		return 1
	fi

	web_fetch_content_type="$(awk '
		tolower($0) ~ /^content-type:/ {
			value=$0
			sub(/^[^:]*:[[:space:]]*/, "", value)
			sub(/[[:space:]]*;.*/, "", value)
			gsub(/^[[:space:]]+/, "", value)
			gsub(/[[:space:]]+$/, "", value)
		}
		END { print value }
	' "$probe_headers")"
	rm -f "$probe_headers" "$probe_status" "$probe_stderr"

	case "$web_fetch_http_status" in
	2??) ;;
	*)
		_web-fetch-report-http-status "$web_fetch_http_status"
		_web-fetch-clean-probe
		return 1
		;;
	esac

	if [ -z "$web_fetch_content_type" ]; then
		echo "web-fetch: could not determine Content-Type (HTTP $web_fetch_http_status $(_web-fetch-http-status-name "$web_fetch_http_status")) for URL \"$web_fetch_url\"" >&2
		_web-fetch-clean-probe
		return 1
	fi

	case "$web_fetch_content_type" in
	text/html | application/xhtml+xml | text/xml | application/xml)
		web_fetch_mode=html
		;;
	application/json | text/plain)
		web_fetch_mode=raw
		;;
	*)
		echo "web-fetch: skipping (HTTP $web_fetch_http_status $(_web-fetch-http-status-name "$web_fetch_http_status"); Content-Type: $web_fetch_content_type)" >&2
		_web-fetch-clean-probe
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
	printf 'fetched_at=%s\nurl=%s\nhttp_status=%s\ncontent_type=%s\n' \
		"$(date -Iseconds)" "$web_fetch_url" "$web_fetch_http_status" "$web_fetch_content_type" >"$web_fetch_meta_cache"
}

_web-fetch-use-cache() {
	local use_cache=false
	if ! $web_fetch_no_cache && [ -f "$web_fetch_content_cache" ] && [ -f "$web_fetch_meta_cache" ]; then
		local now cache_mtime
		now="$(date +%s)"
		cache_mtime="$(stat -c %Y "$web_fetch_content_cache" 2>/dev/null || stat -f %m "$web_fetch_content_cache" 2>/dev/null)"
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
		"$glow_bin" - <"$web_fetch_content_cache"
	elif [ "$web_fetch_mode" = "raw" ] && [ "$web_fetch_content_type" = "application/json" ] && [ -t 1 ] && [ -n "${jq_bin:-}" ] && [ -x "$jq_bin" ]; then
		"$jq_bin" . "$web_fetch_content_cache"
	else
		cat "$web_fetch_content_cache"
	fi
}

_web-fetch-report-page-error() {
	local error_text status_code error_message
	error_text="$(cat "$1" 2>/dev/null)"
	status_code="$(printf '%s\n' "$error_text" | sed -n 's/.*\([0-9][0-9][0-9]\) error.*/\1/p' | head -1)"
	if [ -n "$status_code" ]; then
		_web-fetch-report-http-status "$status_code"
		return
	fi

	case "$error_text" in
	*'ERR_TIMED_OUT'* | *'timeout'* | *'Timeout'*) error_message="Page timed out" ;;
	*'ERR_CONNECTION_REFUSED'* | *'connection refused'*) error_message="Page unavailable" ;;
	*'ERR_NAME_NOT_RESOLVED'* | *'Name or service not known'*) error_message="Page unavailable" ;;
	*'ERR_ABORTED'* | *'Target closed'*) error_message="Page crashed" ;;
	*) error_message="Page unavailable" ;;
	esac
	echo "web-fetch: $error_message${error_text:+ ($error_text)}" >&2
}

_web-fetch-extract-html() {
	local html_source="$1"
	if [ -z "${trafilatura_bin:-}" ] || [ ! -x "$trafilatura_bin" ]; then
		echo "web-fetch: trafilatura is not installed or not executable" >&2
		return 1
	fi

	local format_flag="--markdown"
	$web_fetch_xml_mode && format_flag="--xml"
	local extracted_cache
	extracted_cache="$(mktemp "$web_fetch_cache_dir/.content.XXXXXX")" || return 1

	if ! "$trafilatura_bin" --no-comments --fast "$format_flag" <"$html_source" >"$extracted_cache" 2>/dev/null; then
		rm -f "$extracted_cache"
		return 1
	fi

	if [ ! -s "$extracted_cache" ]; then
		rm -f "$extracted_cache"
		return 1
	fi

	mv "$extracted_cache" "$web_fetch_content_cache" || {
		rm -f "$extracted_cache"
		return 1
	}
	_web-fetch-write-metadata
	_web-fetch-output-cache
}

_web-fetch-fetch-html-browser() {
	if [ -z "${shot_scraper_bin:-}" ] || [ ! -x "$shot_scraper_bin" ]; then
		echo "web-fetch: shot-scraper is not installed or not executable" >&2
		return 1
	fi

	local html_cache ss_stderr ss_exit
	html_cache="$(mktemp "$web_fetch_cache_dir/.html.XXXXXX")" || return 1
	ss_stderr="$(mktemp "$web_fetch_cache_dir/.stderr.XXXXXX")" || {
		rm -f "$html_cache"
		return 1
	}

	"$shot_scraper_bin" html "$web_fetch_url" \
		--output "$html_cache" \
		--user-agent "$web_fetch_user_agent" \
		--wait "$web_fetch_wait_ms" \
		--fail \
		--silent 2>"$ss_stderr"
	ss_exit=$?
	if [ $ss_exit -ne 0 ]; then
		_web-fetch-report-page-error "$ss_stderr"
		rm -f "$ss_stderr" "$html_cache"
		return 1
	fi
	rm -f "$ss_stderr"

	if [ ! -s "$html_cache" ]; then
		rm -f "$html_cache"
		echo "web-fetch: browser response was empty (HTTP $web_fetch_http_status $(_web-fetch-http-status-name "$web_fetch_http_status"))" >&2
		return 1
	fi

	if ! _web-fetch-extract-html "$html_cache"; then
		rm -f "$html_cache"
		echo "web-fetch: HTML extraction failed (HTTP $web_fetch_http_status $(_web-fetch-http-status-name "$web_fetch_http_status"))" >&2
		return 1
	fi
	rm -f "$html_cache"
}

_web-fetch-fetch-html() {
	if _web-fetch-extract-html "$web_fetch_probe_body"; then
		_web-fetch-clean-probe
		return 0
	fi

	_web-fetch-fetch-html-browser
	local fetch_exit=$?
	_web-fetch-clean-probe
	return $fetch_exit
}

_web-fetch-fetch-raw() {
	if [ ! -s "$web_fetch_probe_body" ]; then
		_web-fetch-clean-probe
		echo "web-fetch: response was empty (HTTP $web_fetch_http_status $(_web-fetch-http-status-name "$web_fetch_http_status"))" >&2
		return 1
	fi

	mv "$web_fetch_probe_body" "$web_fetch_content_cache" || {
		_web-fetch-clean-probe
		return 1
	}
	web_fetch_probe_body=""
	_web-fetch-write-metadata
	_web-fetch-output-cache
}

_web-fetch-one() {
	web_fetch_url="$1"
	web_fetch_cache_dir="$HOME/.cache/web-fetch"
	mkdir -p "$web_fetch_cache_dir" || return 1
	_web-fetch-probe || return 1
	_web-fetch-set-cache-paths || {
		_web-fetch-clean-probe
		return 1
	}
	if _web-fetch-use-cache; then
		_web-fetch-clean-probe
		return 0
	fi

	if [ "$web_fetch_mode" = "html" ]; then
		_web-fetch-fetch-html
	else
		_web-fetch-fetch-raw
	fi
	local fetch_exit=$?
	_web-fetch-clean-probe
	return $fetch_exit
}

# Fetch one or more URLs. Options apply to every URL; multiple URLs run in
# parallel (four at a time by default) and print in argument order.
# Options: --jobs N, --xml, --wait MS, --max-lines N, --no-cache, --no-glow
# Example: web-fetch --jobs 2 --max-lines 100 URL_A URL_B URL_C
web-fetch() {
	local urls_file output_dir url index output_file status_file
	local active_jobs fetch_exit url_exit
	web_fetch_xml_mode=false
	web_fetch_wait_ms=500
	web_fetch_user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"
	web_fetch_no_cache=false
	web_fetch_no_glow=false
	web_fetch_max_lines=""
	web_fetch_jobs=4
	web_fetch_url_count=0
	urls_file="$(mktemp "${TMPDIR:-/tmp}/web-fetch.urls.XXXXXX")" || return 1
	web_fetch_urls_file="$urls_file"

	if ! _web-fetch-parse-options "$@"; then
		rm -f "$urls_file"
		return 1
	fi

	if [ "$web_fetch_url_count" -eq 1 ]; then
		IFS= read -r url <"$urls_file"
		rm -f "$urls_file"
		_web-fetch-one "$url"
		return $?
	fi

	output_dir="$(mktemp -d "${TMPDIR:-/tmp}/web-fetch.output.XXXXXX")" || {
		rm -f "$urls_file"
		return 1
	}
	index=0
	active_jobs=0
	set --
	while IFS= read -r url; do
		index=$((index + 1))
		output_file="$output_dir/$index.output"
		status_file="$output_dir/$index.status"
		printf '%s\n' "$url" >"$output_dir/$index.url"
		(
			if _web-fetch-one "$url"; then
				url_exit=0
			else
				url_exit=$?
			fi
			printf '%s\n' "$url_exit" >"$status_file"
		) >"$output_file" 2>&1 &
		set -- "$@" "$!"
		active_jobs=$((active_jobs + 1))
		if [ "$active_jobs" -ge "$web_fetch_jobs" ]; then
			wait "$1" || :
			shift
			active_jobs=$((active_jobs - 1))
		fi
	done <"$urls_file"
	for url in "$@"; do
		wait "$url" || :
	done

	fetch_exit=0
	index=1
	while [ "$index" -le "$web_fetch_url_count" ]; do
		url="$(cat "$output_dir/$index.url")"
		printf '===== %s =====\n\n' "$url"
		cat "$output_dir/$index.output"
		url_exit="$(cat "$output_dir/$index.status" 2>/dev/null)"
		[ "$url_exit" = "0" ] || fetch_exit=1
		[ "$index" -eq "$web_fetch_url_count" ] || printf '\n'
		index=$((index + 1))
	done

	rm -rf "$output_dir"
	rm -f "$urls_file"
	return $fetch_exit
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
