gen-uuid() {
  uuid="$(uuidgen)"

  if [ "$(uname)" = "Darwin" ]; then
    # macOS
    printf "%s" "$uuid" | pbcopy
  elif [ "$(uname)" = "Linux" ]; then
    # Linux (requires xclip or xsel)
    if command -v xclip >/dev/null 2>&1; then
      printf "%s" "$uuid" | xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
      printf "%s" "$uuid" | xsel --clipboard --input
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
