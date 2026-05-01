convert-mp4-to-gif() {
  local input="$1"
  local quality="${2:-60}"
  local fps scale

  if [[ -z "$input" ]]; then
    echo "Usage: convert-mp4-to-gif <input.mp4> [quality:1-100]"
    return 1
  fi

  if [[ ! -f "$input" ]]; then
    echo "Error: file not found: $input"
    return 1
  fi

  if ! [[ "$quality" =~ ^[0-9]+$ ]] || (( quality < 1 || quality > 100 )); then
    echo "Error: quality must be a number from 1 to 100"
    return 1
  fi

  fps=$(( 5 + quality / 10 ))
  scale=$(( 320 + quality * 6 ))

  local output="${input%.*}.gif"

  ffmpeg -y -i "$input" \
    -vf "fps=${fps},scale=${scale}:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
    "$output"

  echo "Created: $output"
}
