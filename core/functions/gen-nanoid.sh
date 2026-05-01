gen-nanoid() {
  local prefix="$1"
  local length=8

  if command -v nanoid >/dev/null 2>&1; then
    id=$(nanoid -s "$length")
  else
    id=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c "$length")
  fi

  if [ -n "$prefix" ]; then
    id="${prefix}-${id}"
  fi

  if command -v pbcopy >/dev/null 2>&1; then
    echo -n "$id" | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    echo -n "$id" | xclip -selection clipboard
  elif command -v wl-copy >/dev/null 2>&1; then
    echo -n "$id" | wl-copy
  fi

  echo "NanoID copied to clipboard: $id"
}
