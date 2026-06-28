# Usage:
#   fs-put ./report.pdf
#   fs-put ./report.pdf /uploads/report.pdf
fs-put() {
  local local_file="$1"
  local remote_path="$2"

  if [ -z "$local_file" ]; then
    echo "Usage: $0 <local_file> [remote_path]" >&2
    return 2
  fi

  if [ ! -f "$local_file" ]; then
    echo "Error: local file not found: $local_file" >&2
    return 1
  fi

  if [ -z "$FILESTASH_URL" ] || [ -z "$FILESTASH_TOKEN" ]; then
    echo "Error: set FILESTASH_URL and FILESTASH_TOKEN first" >&2
    return 1
  fi

  if [ -z "$remote_path" ]; then
    remote_path="/$(basename "$local_file")"
  fi

  $curl_bin --fail-with-body \
    -d @"$local_file" \
    -H "Authorization: Bearer $FILESTASH_TOKEN" \
    "$FILESTASH_URL/api/files/cat?path=$FILESTASH_BASE_PATH$remote_path"
}