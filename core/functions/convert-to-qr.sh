convert-to-qr() {
  if [ -z "$1" ]; then
    echo "Usage: convert-to-qr <client-config>"
    return 1
  fi

  local file="$1"

  qrencode -t ansiutf8 -r "$file"
}
