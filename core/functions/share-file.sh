sharefile() {
	if [ -z "${SHAREFILE_REMOTE_HOST:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_HOST"
		return 1
	fi

	if [ -z "${SHAREFILE_REMOTE_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_BASE"
		return 1
	fi

	if [ -z "${SHAREFILE_PUBLIC_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_PUBLIC_BASE"
		return 1
	fi

	if [ "$#" -eq 0 ]; then
		echo "Usage: sharefile <file> [file ...]"
		return 1
	fi

	local file
	for file in "$@"; do
		if [ ! -f "$file" ]; then
			echo "File not found: $file"
			return 1
		fi
	done

	local date_dir
	date_dir="$(date +%Y%m%d)"

	ssh "$SHAREFILE_REMOTE_HOST" "mkdir -p '$SHAREFILE_REMOTE_BASE/$date_dir'" 2>/dev/null || return 1

	local urls original ext base safe_base id filename url
	urls=""

	for file in "$@"; do
		original="$(basename "$file")"

		if [[ "$original" == *.* ]]; then
			ext="${original##*.}"
			base="${original%.*}"
		else
			ext=""
			base="$original"
		fi

		safe_base="$(printf "%s" "$base" |
			tr '[:upper:]' '[:lower:]' |
			sed 's/[^a-z0-9._-]/-/g; s/-\+/-/g; s/^-//; s/-$//')"

		[ -n "$safe_base" ] || safe_base="file"

		if command -v openssl >/dev/null 2>&1; then
			id="$(openssl rand -hex 8)"
		else
			id="$(date +%s)-$RANDOM"
		fi

		if [ -n "$ext" ]; then
			filename="$safe_base-$id.$ext"
		else
			filename="$safe_base-$id"
		fi

		url="$SHAREFILE_PUBLIC_BASE/$date_dir/$filename"

		printf "Uploading %s... " "$original"

		if rsync -a --quiet "$file" "$SHAREFILE_REMOTE_HOST:$SHAREFILE_REMOTE_BASE/$date_dir/$filename"; then
			printf "done\n"
			printf "%s\n\n" "$url"
			urls="${urls}${url}"$'\n'
		else
			printf "failed\n"
			return 1
		fi
	done

	ssh "$SHAREFILE_REMOTE_HOST" \
		"restorecon -R '$SHAREFILE_REMOTE_BASE/$date_dir' 2>/dev/null || true" 2>/dev/null

	if command -v pbcopy >/dev/null 2>&1; then
		printf "%s" "$urls" | pbcopy
		echo "Copied URL(s) to clipboard."
	fi
}

sharefile-stats() {
	if [ -z "${SHAREFILE_REMOTE_HOST:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_HOST"
		return 1
	fi

	if [ -z "${SHAREFILE_REMOTE_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_BASE"
		return 1
	fi

	ssh -q "$SHAREFILE_REMOTE_HOST" "
    base='$SHAREFILE_REMOTE_BASE'

    if [ ! -d \"\$base\" ]; then
      echo 'Share directory does not exist.'
      exit 1
    fi

    dirs=\$(find \"\$base\" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    files=\$(find \"\$base\" -type f | wc -l | tr -d ' ')
    size=\$(du -sh \"\$base\" 2>/dev/null | awk '{print \$1}')
    oldest=\$(find \"\$base\" -mindepth 1 -maxdepth 1 -type d -printf '%T+ %p\n' 2>/dev/null | sort | head -n 1 | cut -d' ' -f2-)
    newest=\$(find \"\$base\" -mindepth 1 -maxdepth 1 -type d -printf '%T+ %p\n' 2>/dev/null | sort | tail -n 1 | cut -d' ' -f2-)

    echo \"Temporary share stats\"
    echo \"Base: \$base\"
    echo \"Share folders: \$dirs\"
    echo \"Files: \$files\"
    echo \"Disk usage: \$size\"

    if [ -n \"\$oldest\" ]; then
      echo \"Oldest folder: \$(basename \"\$oldest\")\"
    fi

    if [ -n \"\$newest\" ]; then
      echo \"Newest folder: \$(basename \"\$newest\")\"
    fi
  "
}

sharefile-purge() {
	if [ -z "${SHAREFILE_REMOTE_HOST:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_HOST"
		return 1
	fi

	if [ -z "${SHAREFILE_REMOTE_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_BASE"
		return 1
	fi

	if [ -z "${SHAREFILE_PUBLIC_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_PUBLIC_BASE"
		return 1
	fi

	echo "This will archive all temporary shares and clean up."
	echo "Archive: $(dirname "$SHAREFILE_REMOTE_BASE")/a/archive-<timestamp>-<id>.tar.gz"
	printf "Type PURGE to continue: "

	local confirm
	read confirm

	if [ "$confirm" != "PURGE" ]; then
		echo "Aborted."
		return 1
	fi

	ssh -q "$SHAREFILE_REMOTE_HOST" "
    base='$SHAREFILE_REMOTE_BASE'
    public='$SHAREFILE_PUBLIC_BASE'

    if [ ! -d \"\$base\" ]; then
      echo 'Share directory does not exist.'
      exit 1
    fi

    # unique id and timestamp
    if command -v openssl >/dev/null 2>&1; then
      id=\"\$(openssl rand -hex 8)\"
    else
      id=\"\$(date +%s)-\$RANDOM\"
    fi
    timestamp=\"\$(date +%Y%m%d-%H%M%S)\"

    # archive destination: parent directory + /a/
    archive_dir=\"\$(dirname \"\$base\")/a\"
    mkdir -p \"\$archive_dir\"
    archive_file=\"\$archive_dir/archive-\$timestamp-\$id.tar.gz\"

    # compression: prefer pigz on the remote
    if command -v pigz >/dev/null 2>&1; then
      compress_cmd=\"pigz\"
    else
      compress_cmd=\"gzip\"
    fi

    total_files=\"\$(find \"\$base\" -type f | wc -l | tr -d ' ')\"
    if [ \"\$total_files\" -eq 0 ]; then
      echo 'No files to archive.'
      exit 0
    fi

    # archive everything under base
    if ! tar -C \"\$base\" -cf - . | \"\$compress_cmd\" > \"\$archive_file\"; then
      echo 'Archive creation failed — aborting. No files deleted.'
      rm -f \"\$archive_file\"
      exit 1
    fi

    # verify archive is valid and non-empty before deleting originals
    if ! [ -s \"\$archive_file\" ] || ! tar -tzf \"\$archive_file\" >/dev/null 2>&1; then
      echo 'Archive verification failed — aborting. No files deleted.'
      rm -f \"\$archive_file\"
      exit 1
    fi

    archive_size=\"\$(du -h \"\$archive_file\" | awk '{print \$1}')\"
    archived_count=\"\$(tar -tzf \"\$archive_file\" | wc -l | tr -d ' ')\"

    # clean up all files and directories under base
    find \"\$base\" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
    find \"\$base\" -mindepth 1 -maxdepth 1 -type f -delete

    # derive public URL for the archive (replace last path segment with /a)
    archive_public=\"\$(echo \"\$public\" | sed 's,/[^/]*\$,/a,')\"
    echo \"Archived \$archived_count files to: \$archive_file (\$archive_size)\"
    echo \"Public URL: \$archive_public/archive-\$timestamp-\$id.tar.gz\"
    echo \"All temporary shares cleaned up.\"
  "
}

sharefile-remove() {
	if [ -z "${SHAREFILE_REMOTE_HOST:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_HOST"
		return 1
	fi

	if [ -z "${SHAREFILE_REMOTE_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_BASE"
		return 1
	fi

	if [ "$#" -ne 1 ]; then
		echo "Usage: sharefile-remove <id-or-directory>"
		return 1
	fi

	local target
	target="$1"

	case "$target" in
	*/* | *[!A-Za-z0-9._-]* | "")
		echo "Invalid target: $target"
		return 1
		;;
	esac

	ssh -q "$SHAREFILE_REMOTE_HOST" "
    base='$SHAREFILE_REMOTE_BASE'
    target='$target'

    if [ ! -d \"\$base\" ]; then
      echo 'Share directory does not exist.'
      exit 1
    fi

    dirs=\$(find \"\$base\" -mindepth 1 -maxdepth 1 -type d -name \"\$target\" | sort)
    files=\$(find \"\$base\" -type f \( -name \"*-\$target\" -o -name \"*-\$target.*\" \) | sort)
    matches=\$(printf '%s\n%s\n' \"\$dirs\" \"\$files\" | sed '/^\$/d')

    if [ -z \"\$matches\" ]; then
      echo \"No share found for target: \$target\"
      exit 1
    fi

    echo \"Paths to remove:\"
    printf '%s\n' \"\$matches\"
    printf 'Type REMOVE to continue: '
    read confirm

    if [ \"\$confirm\" != 'REMOVE' ]; then
      echo 'Aborted.'
      exit 1
    fi

    printf '%s\n' \"\$dirs\" | sed '/^\$/d' | while read -r dir; do
      rm -rf -- \"\$dir\"
    done

    printf '%s\n' \"\$files\" | sed '/^\$/d' | while read -r file; do
      rm -f -- \"\$file\"
    done

    echo \"Removed share target: \$target\"
  "
}

sharefile-list() {
	if [ -z "${SHAREFILE_REMOTE_HOST:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_HOST"
		return 1
	fi

	if [ -z "${SHAREFILE_REMOTE_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_REMOTE_BASE"
		return 1
	fi

	if [ -z "${SHAREFILE_PUBLIC_BASE:-}" ]; then
		echo "Missing env: SHAREFILE_PUBLIC_BASE"
		return 1
	fi

	local urls
	urls="$(ssh -q "$SHAREFILE_REMOTE_HOST" "
    base='$SHAREFILE_REMOTE_BASE'
    public='$SHAREFILE_PUBLIC_BASE'

    if [ ! -d \"\$base\" ]; then
      echo 'Share directory does not exist.'
      exit 1
    fi

    find \"\$base\" -type f | sort | while read -r file; do
      rel=\${file#\"\$base\"/}
      printf '%s/%s\n' \"\$public\" \"\$rel\"
    done
  ")" || return 1

	if [ -z "$urls" ]; then
		echo "No files found."
		return 0
	fi

	if [ -n "${fzf_bin:-}" ]; then
		local selected
		selected="$(echo "$urls" | "$fzf_bin" --prompt="Select share URL (enter to copy): ")"
		if [ -n "$selected" ]; then
			echo "$selected"
			if command -v pbcopy >/dev/null 2>&1; then
				echo "$selected" | pbcopy
				echo "Copied to clipboard."
			fi
		fi
	else
		echo "$urls" | nl -w1 -s'. '
	fi
}
