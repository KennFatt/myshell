function chad-session() {
  local base="$MYSPACE_HOME/ai/conversations"
  local name="$1"

  if [ -z "$name" ]; then
    if [ -d "$base" ]; then
      local selected
      selected="$(ls -1 "$base" | ${fzf_bin:-fzf})"
      [ -n "$selected" ] || return
      name="$selected"
    else
      return
    fi
  fi

  local session_dir="$base/$name"
  local prompt_file="$session_dir/user.prompt.md"

  mkdir -p "$session_dir"
  [ -f "$prompt_file" ] || printf '# %s\n\n' "$name" > "$prompt_file"
  cd $session_dir
  $EDITOR "$prompt_file"
}
