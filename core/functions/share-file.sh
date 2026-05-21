sharefile() {
	local file="$1"

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

	if [ -z "$file" ]; then
		echo "Usage: sharefile <file>"
		return 1
	fi

	if [ ! -f "$file" ]; then
		echo "File not found: $file"
		return 1
	fi

	local original
	original="$(basename "$file")"

	local ext
	ext="${original##*.}"

	local base
	base="${original%.*}"

	local safe_base
	safe_base="$(echo "$base" |
		tr '[:upper:]' '[:lower:]' |
		sed 's/[^a-z0-9._-]/-/g' |
		sed 's/-\+/-/g' |
		sed 's/^-//' |
		sed 's/-$//')"

	if [ -z "$safe_base" ]; then
		safe_base="file"
	fi

	local filename
	if [ "$original" = "$ext" ]; then
		filename="$safe_base"
	else
		filename="$safe_base.$ext"
	fi

	local id
	if command -v openssl >/dev/null 2>&1; then
		id="$(openssl rand -hex 8)"
	else
		id="$(date +%s)-$RANDOM"
	fi

	ssh "$SHAREFILE_REMOTE_HOST" "mkdir -p '$SHAREFILE_REMOTE_BASE/$id'" 2>/dev/null || return 1

	rsync -av \
		"$file" \
		"$SHAREFILE_REMOTE_HOST:$SHAREFILE_REMOTE_BASE/$id/$filename" || return 1

	ssh "$SHAREFILE_REMOTE_HOST" \
		"restorecon -R '$SHAREFILE_REMOTE_BASE/$id' 2>/dev/null 2>/dev/null || true"

	local url
	url="$SHAREFILE_PUBLIC_BASE/$id/$filename"

	echo "$url"

	if command -v pbcopy >/dev/null 2>&1; then
		printf "%s" "$url" | pbcopy
		echo "Copied to clipboard."
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

	echo "This will delete all temporary shares under:"
	echo "$SHAREFILE_REMOTE_HOST:$SHAREFILE_REMOTE_BASE"
	printf "Type PURGE to continue: "

	local confirm
	read confirm

	if [ "$confirm" != "PURGE" ]; then
		echo "Aborted."
		return 1
	fi

	ssh -q "$SHAREFILE_REMOTE_HOST" "
    base='$SHAREFILE_REMOTE_BASE'

    if [ ! -d \"\$base\" ]; then
      echo 'Share directory does not exist.'
      exit 1
    fi

    find \"\$base\" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
    echo 'All temporary shares purged.'
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

	ssh -q "$SHAREFILE_REMOTE_HOST" "
    base='$SHAREFILE_REMOTE_BASE'
    public='$SHAREFILE_PUBLIC_BASE'

    if [ ! -d \"\$base\" ]; then
      echo 'Share directory does not exist.'
      exit 1
    fi

    find \"\$base\" -type f | sort | while read -r file; do
      rel=\${file#\"\$base\"/}
      echo \"\$public/\$rel\"
    done
  "
}
