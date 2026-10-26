#!/bin/sh

pr-split() {
	local base_ref="HEAD"
	local base_label=""
	local depth="0"
	local json=0
	local show_rules=1
	local show_hunks=0
	local only_cluster=""
	local tmp_dir
	local cur_branch
	local mode="text"
	local p
	local count

	_pr_split_help() {
		cat <<'EOF'
Usage:
  $0
  $0 --depth <n>
  $0 --base <ref>
  $0 --cluster <key>
  $0 --hunks
  $0 --json
  $0 --no-rules
  $0 --help

Behavior:
  - Read-only with respect to the repository: never runs add, reset,
    restore, stash, checkout, fetch, or commit
  - Reads the index only (git diff --cached), so it reports what is
    staged, not what is in the working tree
  - Writes nothing inside the repository; the only writable location is
    a temporary directory under TMPDIR, removed before returning
  - Prints a report meant to help split a staged change set into
    logical commits

Output:
  SUMMARY   branch, base, file counts, insertions and deletions
  FILES     status, insertions, deletions, path per staged file
  CLUSTERS  staged files grouped by directory, or by --depth segments
  RULES     commit-splitting policy

Options:
  --base <ref>     Compare the index against <ref> instead of HEAD.
  --depth <n>      Group clusters by the first n path segments.
                   Default 0 groups by directory.
  --cluster <key>  Restrict the report to clusters whose key starts
                   with <key>.
  --hunks          Count changed hunks per file. One git diff per staged
                   file, so slower. Use it to spot a single file that
                   spans more than one concern.
  --json           Emit JSON instead of text.
  --no-rules       Omit the RULES section.
  -h, --help       Show this help.

Examples:
  $0
  $0 --hunks
  $0 --json
  $0 --depth 2
  $0 --cluster src/lib
  $0 --base develop
EOF
	}

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				_pr_split_help
				return 0
				;;
			-b|--base)
				[[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
				base_ref="$2"
				shift 2
				;;
			-d|--depth)
				[[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
				[[ "$2" =~ ^[0-9]+$ ]] || { echo "Depth must be a non-negative integer." >&2; return 1; }
				depth="$2"
				shift 2
				;;
			-c|--cluster)
				[[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
				only_cluster="$2"
				shift 2
				;;
			--hunks)
				show_hunks=1
				shift
				;;
			--json)
				json=1
				shift
				;;
			--no-rules)
				show_rules=0
				shift
				;;
			*)
				echo "Unknown argument: $1" >&2
				_pr_split_help >&2
				return 1
				;;
		esac
	done

	if [[ -z "${git_bin:-}" ]]; then
		echo "pr-split: git_bin is not set; load MyShell first (source ~/.myshell/_init.sh)." >&2
		return 1
	fi

	if ! $git_bin rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "Not inside a Git repository." >&2
		return 1
	fi

	if ! $git_bin rev-parse --verify "$base_ref" >/dev/null 2>&1; then
		if [[ "$base_ref" == "HEAD" ]]; then
			# Unborn branch: diff the index against the empty tree.
			base_ref="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
			base_label="HEAD (no commits yet)"
		else
			echo "Base ref not found: $base_ref" >&2
			return 1
		fi
	fi

	[[ -n "$base_label" ]] || base_label="$base_ref"

	if [[ "$json" -eq 1 ]]; then
		mode="json"
	fi

	tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/pr-split.XXXXXX")" || {
		echo "Cannot create a temporary directory." >&2
		return 1
	}

	_pr_split_cleanup() {
		rm -rf "$tmp_dir"
	}

	if [[ "$base_ref" == "HEAD" ]]; then
		$git_bin diff --cached --name-status -M > "$tmp_dir/name-status" 2>/dev/null || { _pr_split_cleanup; return 1; }
		$git_bin diff --cached --numstat -M > "$tmp_dir/numstat" 2>/dev/null || { _pr_split_cleanup; return 1; }
	else
		$git_bin diff --cached --name-status -M "$base_ref" > "$tmp_dir/name-status" 2>/dev/null || { _pr_split_cleanup; return 1; }
		$git_bin diff --cached --numstat -M "$base_ref" > "$tmp_dir/numstat" 2>/dev/null || { _pr_split_cleanup; return 1; }
	fi

	if [[ ! -s "$tmp_dir/name-status" ]]; then
		_pr_split_cleanup
		if [[ "$mode" == "json" ]]; then
			printf '{\n  "files": [],\n  "clusters": [],\n  "rules": []\n}\n'
		else
			echo "No staged changes."
		fi
		return 0
	fi

	# numstat compacts renames as "dir/{old => new}/file", so expand the
	# destination path before joining against name-status rows.
	awk -F'\t' '
		function dest(p,   i, pre, rest, j, mid, suf, k) {
			if (index(p, "{") == 0) return p
			i = index(p, "{")
			pre = substr(p, 1, i - 1)
			rest = substr(p, i + 1)
			j = index(rest, "}")
			mid = substr(rest, 1, j - 1)
			suf = substr(rest, j + 1)
			k = index(mid, " => ")
			return pre substr(mid, k + 4) suf
		}
		{
			d = dest($3)
			cadd[d] = $1
			cdel[d] = $2
		}
		END {
			for (d in cadd) printf "%s\t%s\t%s\n", cadd[d], cdel[d], d
		}
	' "$tmp_dir/numstat" > "$tmp_dir/counts"

	# table columns: status, insertions, deletions, old path, path
	awk -F'\t' '
		NR == FNR {
			cadd[$3] = $1
			cdel[$3] = $2
			next
		}
		{
			if ($1 ~ /^[RC]/) {
				old = $2
				p = $3
			} else {
				old = ""
				p = $2
			}
			a = (p in cadd) ? cadd[p] : "-"
			d = (p in cdel) ? cdel[p] : "-"
			printf "%s\t%s\t%s\t%s\t%s\n", $1, a, d, old, p
		}
	' "$tmp_dir/counts" "$tmp_dir/name-status" > "$tmp_dir/table"

	if [[ "$show_hunks" -eq 1 ]]; then
		awk -F'\t' '{ printf "%s\n", $5 }' "$tmp_dir/table" > "$tmp_dir/paths"
		: > "$tmp_dir/hunks"
		while IFS= read -r p; do
			[[ -n "$p" ]] || continue
			if [[ "$base_ref" == "HEAD" ]]; then
				count="$($git_bin diff --cached -U0 -M -- ":(literal)$p" 2>/dev/null | grep -c '^@@')"
			else
				count="$($git_bin diff --cached -U0 -M "$base_ref" -- ":(literal)$p" 2>/dev/null | grep -c '^@@')"
			fi
			printf '%s\t%s\n' "$count" "$p" >> "$tmp_dir/hunks"
		done < "$tmp_dir/paths"
		awk -F'\t' '
			NR == FNR { h[$2] = $1; next }
			{ printf "%s\t%s\n", $0, (($5 in h) ? h[$5] : "0") }
		' "$tmp_dir/hunks" "$tmp_dir/table" > "$tmp_dir/table-hunks"
		mv "$tmp_dir/table-hunks" "$tmp_dir/table"
	fi

	if [[ -n "$only_cluster" ]]; then
		awk -F'\t' -v depth="$depth" -v only="$only_cluster" '
			function cluster_of(p, d,   parts, cnt, i, out) {
				if (d == 0) {
					if (index(p, "/") == 0) return "(root)"
					sub(/\/[^\/]*$/, "", p)
					return p
				}
				cnt = split(p, parts, "/")
				if (cnt <= d) return p
				out = parts[1]
				for (i = 2; i <= d; i++) out = out "/" parts[i]
				return out
			}
			{
				k = cluster_of($5, depth)
				if (index(k, only) != 1) next
				print
			}
		' "$tmp_dir/table" > "$tmp_dir/table-filtered"
		mv "$tmp_dir/table-filtered" "$tmp_dir/table"
	fi

	if [[ "$show_rules" -eq 1 ]]; then
		cat > "$tmp_dir/rules" <<'EOF'
One concern per commit: if two groups of files changed for unrelated reasons, they belong in separate commits.
Every commit must build and pass its own tests; never commit a state that only works once the next commit lands.
Keep a source file and its test file in the same commit.
Land a pure rename or move on its own when the content is unchanged; combine it with edits only when the edit requires the new name.
A deletion belongs in the same commit as the change that removes its last reference.
Shared helpers under lib land before, or together with, the code that consumes them.
Order commits so each one is independently understandable, smallest consistent tree first.
Do not mix formatting-only or unrelated cleanup with behaviour changes.
Config and route registrations travel with the feature that needs them.
When one file spans two concerns, stage it partially instead of widening the commit.
EOF
	else
		: > "$tmp_dir/rules"
	fi

	cur_branch="$($git_bin branch --show-current 2>/dev/null)"
	[[ -n "$cur_branch" ]] || cur_branch="(detached HEAD)"

	awk -F'\t' \
		-v depth="$depth" \
		-v mode="$mode" \
		-v wh="$show_hunks" \
		-v cur_branch="$cur_branch" \
		-v base_label="$base_label" \
		-v rules_file="$tmp_dir/rules" '
		function esc(s) {
			gsub(/\\/, "\\\\", s)
			gsub(/"/, "\\\"", s)
			return s
		}

		function cluster_of(p, d,   parts, cnt, i, out) {
			if (d == 0) {
				if (index(p, "/") == 0) return "(root)"
				sub(/\/[^\/]*$/, "", p)
				return p
			}
			cnt = split(p, parts, "/")
			if (cnt <= d) return p
			out = parts[1]
			for (i = 2; i <= d; i++) out = out "/" parts[i]
			return out
		}

		function num(v) {
			return (v == "-" ? 0 : v + 0)
		}

		function sign(v, pfx) {
			return (v == "-") ? "-" : sprintf("%s%d", pfx, v)
		}

		{
			n++
			status[n] = $1
			adds[n] = $2
			dels[n] = $3
			oldp[n] = $4
			path[n] = $5
			hunks[n] = (NF >= 6) ? $6 : "-"

			k = cluster_of($5, depth)
			keyof[n] = k
			if (!(k in seen)) {
				seen[k] = 1
				order[++ncl] = k
			}
			cfiles[k]++
			cadd[k] += num($2)
			cdel[k] += num($3)

			if ($1 ~ /^[RC]/) renamed++
			else if ($1 ~ /^A/) added++
			else if ($1 ~ /^D/) deleted++
			else modified++

			tadd += num($2)
			tdel += num($3)
		}

		END {
			for (i = 2; i <= ncl; i++) {
				v = order[i]
				j = i - 1
				while (j >= 1 && (cfiles[order[j]] < cfiles[v] || (cfiles[order[j]] == cfiles[v] && order[j] > v))) {
					order[j + 1] = order[j]
					j--
				}
				order[j + 1] = v
			}

			if (mode == "json") {
				printf "{\n"
				printf "  \"branch\": \"%s\",\n", esc(cur_branch)
				printf "  \"base\": \"%s\",\n", esc(base_label)
				printf "  \"summary\": { \"files\": %d, \"added\": %d, \"modified\": %d, \"deleted\": %d, \"renamed\": %d, \"insertions\": %d, \"deletions\": %d },\n", n, added, modified, deleted, renamed, tadd, tdel
				printf "  \"files\": ["
				for (i = 1; i <= n; i++) {
					if (i > 1) printf ","
					printf "\n    { \"status\": \"%s\", \"path\": \"%s\", ", esc(status[i]), esc(path[i])
					printf "\"old_path\": %s, ", (oldp[i] != "") ? "\"" esc(oldp[i]) "\"" : "null"
					printf "\"insertions\": %s, \"deletions\": %s, ", (adds[i] == "-") ? "null" : adds[i], (dels[i] == "-") ? "null" : dels[i]
					printf "\"cluster\": \"%s\"", esc(keyof[i])
					if (wh) printf ", \"hunks\": %s", (hunks[i] == "-") ? "null" : hunks[i]
					printf " }"
				}
				if (n > 0) printf "\n  "
				printf "],\n"
				printf "  \"clusters\": ["
				for (c = 1; c <= ncl; c++) {
					if (c > 1) printf ","
					k = order[c]
					printf "\n    { \"key\": \"%s\", \"files\": %d, \"insertions\": %d, \"deletions\": %d, \"paths\": [", esc(k), cfiles[k], cadd[k], cdel[k]
					first = 1
					for (i = 1; i <= n; i++) {
						if (keyof[i] != k) continue
						if (!first) printf ", "
						printf "\"%s\"", esc(path[i])
						first = 0
					}
					printf "] }"
				}
				if (ncl > 0) printf "\n  "
				printf "],\n"
				printf "  \"rules\": ["
				r = 0
				while ((getline line < rules_file) > 0) {
					if (++r > 1) printf ","
					printf "\n    \"%s\"", esc(line)
				}
				close(rules_file)
				if (r > 0) printf "\n  "
				printf "]\n}\n"
				exit 0
			}

			print "SUMMARY"
			printf "  branch   %s\n", cur_branch
			printf "  base     %s\n", base_label
			printf "  files    %d\n", n
			printf "  changed  +%d -%d\n", tadd, tdel
			printf "  kinds    %d added, %d modified, %d deleted, %d renamed\n", added, modified, deleted, renamed
			print ""
			print "FILES"
			for (i = 1; i <= n; i++) {
				line = sprintf("  %-5s %8s %8s", status[i], sign(adds[i], "+"), sign(dels[i], "-"))
				if (wh) line = line sprintf(" %6s", (hunks[i] == "-") ? "-" : hunks[i] "h")
				line = line "  " path[i]
				if (oldp[i] != "") line = line " (from " oldp[i] ")"
				print line
			}
			if (wh) print "  (trailing column is changed hunks per file)"
			print ""
			print "CLUSTERS"
			for (c = 1; c <= ncl; c++) {
				k = order[c]
				printf "  %d file%s  +%d -%d  %s\n", cfiles[k], (cfiles[k] == 1) ? "" : "s", cadd[k], cdel[k], k
				for (i = 1; i <= n; i++) {
					if (keyof[i] != k) continue
					printf "    %-5s %s\n", status[i], path[i]
				}
			}
			if (n == 0) print "  (nothing matches the filter)"
			printf "\n"
			r = 0
			while ((getline line < rules_file) > 0) {
				if (r == 0) print "RULES"
				r++
				print "  - " line
			}
			close(rules_file)
		}
	' "$tmp_dir/table"

	_pr_split_cleanup
	return 0
}
