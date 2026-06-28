rga-fzf() {
  RG_PREFIX="$rga_bin --files-with-matches"

  local file
  file="$(
    FZF_DEFAULT_COMMAND="$RG_PREFIX '$*'" \
    $fzf_bin \
      --phony \
      --query "$*" \
      --bind "change:reload:$RG_PREFIX {q} || true" \
      --preview "$rga_bin --pretty --context 20 {q} {}" \
      --preview-window "right:50%:wrap"
  )" || return

  printf '%s\n' "$file"
}