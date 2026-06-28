gen-uuid() {
  uuid="$($uuidgen_bin)"

  if [ "$(uname)" = "Darwin" ]; then
    # macOS
    printf "%s" "$uuid" | $pbcopy_bin
  elif [ "$(uname)" = "Linux" ]; then
    # Linux (requires xclip or xsel)
    if [ -n "$xclip_bin" ]; then
      printf "%s" "$uuid" | $xclip_bin -selection clipboard
    elif [ -n "$xsel_bin" ]; then
      printf "%s" "$uuid" | $xsel_bin --clipboard --input
    else
      echo "Error: no clipboard tool (xclip/xsel) found." >&2
      return 1
    fi
  else
    echo "Unsupported OS: $(uname)" >&2
    return 1
  fi

  echo "UUID copied to clipboard: $uuid"
}
