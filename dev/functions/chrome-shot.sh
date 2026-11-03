#!/bin/sh
# chrome-shot - preset viewport screenshots of a running browser session
#
# Captures page content (no tab strip, address bar or DevTools) from tabs of an
# already-running browser that exposes CDP. Cookies, auth and app state are the
# real thing because agent-browser attaches to your session over CDP.
#
# Presets: default (no emulation), qa (1280x593@1.5), figma (1440x1024@1),
# mobile (iPhone 14). A run captures all four unless one is named.
#
# Usage, examples and notes: chrome-shot --help
# Output: $AGENT_BROWSER_SCREENSHOT_DIR/<preset>-<host-slug>-<timestamp>.png,
# one shared timestamp per run.
#
# A target is always required (--tab or --url). There is no automatic
# active-tab detection: agent-browser's active flag is its session binding, not
# window focus, and CDP exposes no focus query. List targets with --list.

_chrome-shot-ab() {
	"$chrome_shot_bin" --cdp "$chrome_shot_port" --session "$chrome_shot_session" "$@"
}

_chrome-shot-usage() {
	cat <<'USAGE'
chrome-shot - preset viewport screenshots of a running browser session

Usage:
  chrome-shot --list
  chrome-shot [preset | --all] (--tab <ref> | --url <url>) [--new-tab] [--full]
              [--out <path>] [--size <WxH[@dpr]>] [--port <n>]

Presets (a run captures all four unless you name one):
  default  no emulation, the tab's real viewport (per tab, e.g. 1920x963@1)
  qa       1280x593 @1.5  -> 1920x890 PNG
  figma    1440x1024 @1   -> 1440x1024 PNG, 1:1 with Figma design pixels
  mobile   iPhone 14, 390x844 @3 -> 1170x2532 PNG, mobile UA and touch

Options:
  --list        show targetable tabs (index, target id, title, url), then exit
  --tab <ref>   capture an open tab: index, target id or unique prefix,
                tab id (t3), or title / url text
  --url <url>   reuse the open tab with that url, else open a temporary tab
  --new-tab     force a temporary tab even when the url is already open
  --all         capture every preset (already the default)
  --full        capture full scroll height instead of the viewport
  --out <path>  output directory, or an exact .png path for a single preset
  --size <spec> one ad-hoc size instead of the presets, e.g. 1920x1080@2
  --port <n>    CDP port, default 9222
  --help        this text

Examples:
  chrome-shot --list
  chrome-shot --tab 5                          all four presets for tab 5
  chrome-shot qa --tab 5                       only the qa preset
  chrome-shot --url http://localhost:2828/foo   reuse if open, else temp tab
  chrome-shot figma --tab 5 --new-tab --full --out ~/Desktop/shots

Notes:
  A target is required: there is no automatic active-tab detection, because
  agent-browser's active flag is its session binding, not window focus, and
  CDP has no focus query. Use --list and name the tab.
  A viewport preset rescales the target tab while it is captured; the override
  is dropped when the session closes at the end of the run.
  default is captured first so the untouched viewport is always recorded.
  Files land in $AGENT_BROWSER_SCREENSHOT_DIR (default $PWD) as
  <preset>-<host-slug>-<timestamp>.png, one shared timestamp per run.
USAGE
}

_chrome-shot-detach() {
	_chrome-shot-ab close >/dev/null 2>&1
	[ -n "$chrome_shot_tabs_file" ] && rm -f "$chrome_shot_tabs_file"
	return 0
}

_chrome-shot-require-cdp() {
	local probe
	probe="$("${curl_bin:-curl}" -s -m 2 "http://127.0.0.1:$chrome_shot_port/json/version" 2>/dev/null)"
	[ -n "$probe" ] && return 0
	echo "chrome-shot: no CDP endpoint on port $chrome_shot_port" >&2
	echo "  start the browser with remote debugging, for example:" >&2
	echo "  /Applications/Chromium.app/Contents/MacOS/Chromium --remote-debugging-port=$chrome_shot_port" >&2
	return 1
}

_chrome-shot-tabs() {
	local json
	json="$(_chrome-shot-ab tab list --json 2>/dev/null)" || return 1
	[ -n "$json" ] || return 1
	printf '%s' "$json" | "${jq_bin:-jq}" -r '
		.data.tabs | map(select(.type == "page")) | to_entries[]
		| [(.key + 1), .value.tabId, .value.targetId, .value.title, .value.url]
		| @tsv' >"$chrome_shot_tabs_file" 2>/dev/null || return 1
	[ -s "$chrome_shot_tabs_file" ]
}

_chrome-shot-print-tabs() {
	awk -F'\t' 'BEGIN { printf "  %-4s %-10s %-46s %s\n", "#", "target", "title", "url" }
		{
			title = $4; url = $5
			if (length(title) > 45) title = substr(title, 1, 42) "..."
			if (length(url) > 70) url = substr(url, 1, 67) "..."
			printf "  %-4s %-10s %-46s %s\n", $1, substr($3, 1, 8), title, url
		}' "$chrome_shot_tabs_file"
}

_chrome-shot-hits() {
	case "$1" in
	index) awk -F'\t' -v r="$2" '$1 == r' "$chrome_shot_tabs_file" ;;
	target) awk -F'\t' -v r="$3" 'tolower($3) == r' "$chrome_shot_tabs_file" ;;
	prefix) awk -F'\t' -v r="$3" 'index(tolower($3), r) == 1' "$chrome_shot_tabs_file" ;;
	tabid) awk -F'\t' -v r="$3" 'tolower($2) == r' "$chrome_shot_tabs_file" ;;
	title) awk -F'\t' -v r="$3" 'index(tolower($4), r) > 0' "$chrome_shot_tabs_file" ;;
	url) awk -F'\t' -v r="$3" 'index(tolower($5), r) > 0' "$chrome_shot_tabs_file" ;;
	esac
}

_chrome-shot-find-tab() {
	local ref_raw ref_lower tier hits count
	ref_raw="$1"
	ref_lower="$(printf '%s' "$ref_raw" | tr '[:upper:]' '[:lower:]')"
	set -- index target prefix tabid title url
	for tier in "$@"; do
		hits="$(_chrome-shot-hits "$tier" "$ref_raw" "$ref_lower" 2>/dev/null)"
		[ -n "$hits" ] || continue
		count="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
		if [ "$count" -gt 1 ]; then
			echo "chrome-shot: --tab '$ref_raw' matches $count tabs, refusing to guess:" >&2
			printf '%s\n' "$hits" | awk -F'\t' '{ printf "  %-4s %-10s %s\n", $1, substr($3, 1, 8), $4 }' >&2
			echo "  pass the index or the target id instead" >&2
			return 1
		fi
		printf '%s\n' "$hits"
		return 0
	done
	return 2
}

_chrome-shot-url-slug() {
	local host slug
	host="$(printf '%s' "$1" | sed -e 's|^[A-Za-z][A-Za-z0-9+.-]*://||' -e 's|[/?#].*$||' -e 's|^[^@]*@||' -e 's|:[0-9]*$||' -e 's|^www\.||')"
	slug="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/--*/-/g' -e 's/^-//' -e 's/-$//')"
	printf '%s\n' "${slug:-tab}"
}

_chrome-shot-parse-size() {
	local raw wh dpr width height
	raw="$1"
	case "$raw" in
	*@*) wh="${raw%@*}"; dpr="${raw##*@}" ;;
	*) wh="$raw"; dpr=1 ;;
	esac
	case "$wh" in
	*x*) ;;
	*)
		echo "chrome-shot: --size expects WxH[@dpr], got '$raw'" >&2
		return 1
		;;
	esac
	width="${wh%x*}"
	height="${wh#*x}"
	case "$width:$height:$dpr" in
	'' | *[!0-9.:]* | :* | *:)
		echo "chrome-shot: --size expects WxH[@dpr] with numbers, got '$raw'" >&2
		return 1
		;;
	esac
	chrome_shot_size_w="$width"
	chrome_shot_size_h="$height"
	chrome_shot_size_dpr="$dpr"
}

_chrome-shot-apply-preset() {
	case "$1" in
	default) return 0 ;;
	qa) _chrome-shot-ab set viewport 1280 593 1.5 >/dev/null 2>&1 ;;
	figma) _chrome-shot-ab set viewport 1440 1024 1 >/dev/null 2>&1 ;;
	mobile) _chrome-shot-ab set device "iPhone 14" >/dev/null 2>&1 ;;
	custom) _chrome-shot-ab set viewport "$chrome_shot_size_w" "$chrome_shot_size_h" "$chrome_shot_size_dpr" >/dev/null 2>&1 ;;
	*)
		echo "chrome-shot: unknown preset '$1'" >&2
		return 1
		;;
	esac
}

_chrome-shot-measure() {
	local dims
	dims="$(_chrome-shot-ab eval 'innerWidth+"x"+innerHeight+"@"+devicePixelRatio' 2>/dev/null | tr -d '"')"
	case "$dims" in
	*x*@*) printf '%s\n' "$dims" ;;
	*) printf '?\n' ;;
	esac
}

_chrome-shot-capture() {
	local preset dims shot_path
	preset="$1"
	chrome_shot_index=$((chrome_shot_index + 1))

	if ! _chrome-shot-apply-preset "$preset"; then
		echo "chrome-shot: failed to apply preset '$preset'" >&2
		return 1
	fi

	dims="$(_chrome-shot-measure)"

	case "$chrome_shot_out_target" in
	*.png) shot_path="$chrome_shot_out_target" ;;
	*) shot_path="$chrome_shot_dir/$preset-$chrome_shot_slug-$chrome_shot_run_ts.png" ;;
	esac

	if [ "$chrome_shot_full" = true ]; then
		_chrome-shot-ab screenshot --full "$shot_path" >/dev/null 2>&1
	else
		_chrome-shot-ab screenshot "$shot_path" >/dev/null 2>&1
	fi

	[ -f "$shot_path" ] || {
		echo "chrome-shot: screenshot failed for preset '$preset'" >&2
		return 1
	}

	printf 'saved: %s (%s, target=%s, %s/%s)\n' \
		"$shot_path" "$dims" "$chrome_shot_target_kind" "$chrome_shot_index" "$chrome_shot_total"
}

_chrome-shot-cleanup() {
	if [ "$chrome_shot_temp_tab" = true ] && [ -n "$chrome_shot_target_id" ]; then
		_chrome-shot-ab tab "$chrome_shot_target_id" >/dev/null 2>&1 &&
			_chrome-shot-ab tab close >/dev/null 2>&1
	fi
	_chrome-shot-ab close >/dev/null 2>&1
	[ -n "$chrome_shot_tabs_file" ] && rm -f "$chrome_shot_tabs_file"
	chrome_shot_temp_tab=false
	return 0
}

_chrome-shot-resolve-tab() {
	local hits rc
	hits="$(_chrome-shot-find-tab "$chrome_shot_ref")"
	rc=$?
	case "$rc" in
	0) ;;
	2)
		echo "chrome-shot: no tab matches '$chrome_shot_ref', available tabs:" >&2
		_chrome-shot-print-tabs >&2
		return 1
		;;
	*) return 1 ;;
	esac
	chrome_shot_target_id="$(printf '%s\n' "$hits" | awk -F'\t' '{ print $3 }')"
	chrome_shot_target_url="$(printf '%s\n' "$hits" | awk -F'\t' '{ print $5 }')"
	chrome_shot_target_kind=tab
	_chrome-shot-ab tab "$chrome_shot_target_id" >/dev/null 2>&1 && return 0
	echo "chrome-shot: cannot bind tab $chrome_shot_target_id (closed or pinned by another session)" >&2
	return 1
}

_chrome-shot-resolve-url() {
	local normalized candidate new_json idx tab_id target_id title url
	normalized="$(printf '%s' "$chrome_shot_ref" | sed -e 's|/$||')"
	chrome_shot_target_id=""
	chrome_shot_target_url=""

	if [ "$chrome_shot_new_tab" = false ]; then
		while IFS="$(printf '\t')" read -r idx tab_id target_id title url; do
			[ -n "$target_id" ] || continue
			candidate="$(printf '%s' "$url" | sed -e 's|/$||')"
			[ "$candidate" = "$normalized" ] || continue
			chrome_shot_target_id="$target_id"
			chrome_shot_target_url="$url"
			break
		done <"$chrome_shot_tabs_file"
	fi

	if [ -n "$chrome_shot_target_id" ]; then
		chrome_shot_target_kind=reused-url
		_chrome-shot-ab tab "$chrome_shot_target_id" >/dev/null 2>&1 && return 0
		echo "chrome-shot: cannot bind the open tab for that url" >&2
		return 1
	fi

	new_json="$(_chrome-shot-ab tab new "$chrome_shot_ref" --json 2>/dev/null)"
	chrome_shot_target_id="$(printf '%s' "$new_json" | "${jq_bin:-jq}" -r '.data.targetId // empty' 2>/dev/null)"
	if [ -z "$chrome_shot_target_id" ]; then
		echo "chrome-shot: cannot open $chrome_shot_ref" >&2
		return 1
	fi
	chrome_shot_temp_tab=true
	chrome_shot_target_kind=new-tab
	chrome_shot_target_url="$chrome_shot_ref"
	_chrome-shot-ab wait --load load >/dev/null 2>&1 || true
	return 0
}

_chrome-shot-resolve-output() {
	if [ -n "$chrome_shot_out" ]; then
		case "$chrome_shot_out" in
		*.png)
			if [ "$chrome_shot_count" -gt 1 ]; then
				echo "chrome-shot: --out with a .png file needs a single preset" >&2
				return 1
			fi
			chrome_shot_out_target="$chrome_shot_out"
			chrome_shot_dir="$(dirname "$chrome_shot_out")"
			;;
		*) chrome_shot_dir="$chrome_shot_out" ;;
		esac
	else
		chrome_shot_dir="${AGENT_BROWSER_SCREENSHOT_DIR:-$PWD}"
	fi
	mkdir -p "$chrome_shot_dir" 2>/dev/null && return 0
	echo "chrome-shot: cannot create output directory $chrome_shot_dir" >&2
	return 1
}

_chrome-shot-run() {
	chrome_shot_run_ts="$(date +%s)"
	chrome_shot_slug="$(_chrome-shot-url-slug "$chrome_shot_target_url")"

	case "$chrome_shot_preset" in
	"" | all)
		chrome_shot_count=4
		chrome_shot_total=4
		;;
	*)
		chrome_shot_count=1
		chrome_shot_total=1
		;;
	esac

	_chrome-shot-resolve-output || return 1

	case "$chrome_shot_preset" in
	"" | all)
		_chrome-shot-capture default || return 1
		_chrome-shot-capture qa || return 1
		_chrome-shot-capture figma || return 1
		_chrome-shot-capture mobile || return 1
		;;
	*) _chrome-shot-capture "$chrome_shot_preset" || return 1 ;;
	esac

	if [ "$chrome_shot_count" -gt 1 ]; then
		printf '%s images from 1 tab\n' "$chrome_shot_count"
	fi
	return 0
}

chrome-shot() {
	local chrome_shot_bin chrome_shot_session chrome_shot_port chrome_shot_preset
	local chrome_shot_ref chrome_shot_target_kind chrome_shot_target_id chrome_shot_target_url
	local chrome_shot_full chrome_shot_out chrome_shot_out_target chrome_shot_new_tab
	local chrome_shot_temp_tab chrome_shot_list chrome_shot_dir chrome_shot_tabs_file
	local chrome_shot_run_ts chrome_shot_slug chrome_shot_count chrome_shot_index chrome_shot_total
	local chrome_shot_size chrome_shot_size_w chrome_shot_size_h chrome_shot_size_dpr
	local opt value rc

	chrome_shot_bin="${agent_browser_bin:-$(command -v agent-browser 2>/dev/null)}"
	chrome_shot_session="chrome-shot-$$"
	chrome_shot_port=9222
	chrome_shot_preset=""
	chrome_shot_ref=""
	chrome_shot_target_kind=""
	chrome_shot_target_id=""
	chrome_shot_target_url=""
	chrome_shot_full=false
	chrome_shot_new_tab=false
	chrome_shot_temp_tab=false
	chrome_shot_list=false
	chrome_shot_out=""
	chrome_shot_out_target=""
	chrome_shot_dir=""
	chrome_shot_tabs_file=""
	chrome_shot_run_ts=""
	chrome_shot_slug="tab"
	chrome_shot_count=0
	chrome_shot_index=0
	chrome_shot_total=0
	chrome_shot_size=""
	chrome_shot_size_w=""
	chrome_shot_size_h=""
	chrome_shot_size_dpr=""
	rc=0

	while [ $# -gt 0 ]; do
		case "$1" in
		--help | -h)
			_chrome-shot-usage
			return 0
			;;
		--list) chrome_shot_list=true ;;
		--all) chrome_shot_preset=all ;;
		--new-tab) chrome_shot_new_tab=true ;;
		--full | -f) chrome_shot_full=true ;;
		--tab | --url | --out | --size | --port)
			opt="$1"
			shift
			value="${1:-}"
			if [ -z "$value" ]; then
				echo "chrome-shot: $opt needs a value (try --help)" >&2
				return 1
			fi
			case "$opt" in
			--tab) chrome_shot_target_kind=tab; chrome_shot_ref="$value" ;;
			--url) chrome_shot_target_kind=url; chrome_shot_ref="$value" ;;
			--out) chrome_shot_out="$value" ;;
			--size) chrome_shot_size="$value" ;;
			--port) chrome_shot_port="$value" ;;
			esac
			;;
		-*)
			echo "chrome-shot: unknown option '$1' (try --help)" >&2
			return 1
			;;
		*)
			case "$chrome_shot_preset" in
			"") chrome_shot_preset="$1" ;;
			*)
				echo "chrome-shot: unexpected extra argument '$1'" >&2
				return 1
				;;
			esac
			;;
		esac
		shift
	done

	case "$chrome_shot_port" in
	'' | *[!0-9]*)
		echo "chrome-shot: --port needs a number, got '$chrome_shot_port'" >&2
		return 1
		;;
	esac

	case "$chrome_shot_preset" in
	"" | all | default | qa | figma | mobile) ;;
	*)
		echo "chrome-shot: unknown preset '$chrome_shot_preset'" >&2
		echo "  presets: default, qa, figma, mobile (omit for all four)" >&2
		return 1
		;;
	esac

	if [ -n "$chrome_shot_size" ]; then
		case "$chrome_shot_preset" in
		"" | all) chrome_shot_preset=custom ;;
		*)
			echo "chrome-shot: --size replaces the preset set, drop '$chrome_shot_preset'" >&2
			return 1
			;;
		esac
		_chrome-shot-parse-size "$chrome_shot_size" || return 1
	fi

	if [ -z "$chrome_shot_bin" ]; then
		echo "chrome-shot: agent-browser not found (add it to PATH)" >&2
		return 1
	fi

	_chrome-shot-require-cdp || return 1

	chrome_shot_tabs_file="$(mktemp "${TMPDIR:-/tmp}/chrome-shot-tabs.XXXXXX")" || {
		echo "chrome-shot: cannot create a temp file" >&2
		return 1
	}

	if ! _chrome-shot-tabs; then
		_chrome-shot-detach
		echo "chrome-shot: cannot read the tab list from port $chrome_shot_port" >&2
		return 1
	fi

	if [ "$chrome_shot_list" = true ]; then
		_chrome-shot-print-tabs
		_chrome-shot-detach
		return 0
	fi

	if [ -z "$chrome_shot_ref" ]; then
		echo "chrome-shot: no target given, pick one:" >&2
		_chrome-shot-print-tabs >&2
		echo "  e.g. chrome-shot --tab 3   or   chrome-shot qa --url http://localhost:3000" >&2
		_chrome-shot-detach
		return 1
	fi

	case "$chrome_shot_target_kind" in
	tab) _chrome-shot-resolve-tab || rc=1 ;;
	url) _chrome-shot-resolve-url || rc=1 ;;
	esac

	if [ "$rc" -ne 0 ]; then
		_chrome-shot-detach
		return 1
	fi

	_chrome-shot-run || rc=1

	_chrome-shot-cleanup

	if [ "$rc" -ne 0 ]; then
		echo "chrome-shot: capture aborted" >&2
		return 1
	fi
	return 0
}
