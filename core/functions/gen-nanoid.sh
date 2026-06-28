gen-nanoid() {
  local prefix="$1"
  local length=8

  if [ -n "$nanoid_bin" ]; then
    id=$($nanoid_bin -s "$length")
  else
    id=$($openssl_bin rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c "$length")
  fi

  if [ -n "$prefix" ]; then
    id="${prefix}-${id}"
  fi

  if [ -n "$pbcopy_bin" ]; then
    echo -n "$id" | $pbcopy_bin
  elif [ -n "$xclip_bin" ]; then
    echo -n "$id" | $xclip_bin -selection clipboard
  elif [ -n "$wl_copy_bin" ]; then
    echo -n "$id" | $wl_copy_bin
  fi

  echo "NanoID copied to clipboard: $id"
}
