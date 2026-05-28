bin-install() {
  if [ "$#" -ne 1 ]; then
    printf 'Usage: bin-install <path-to-binary>\n' >&2
    return 2
  fi

  src=$1

  if [ ! -e "$src" ]; then
    printf 'Error: file does not exist: %s\n' "$src" >&2
    return 1
  fi

  if [ ! -f "$src" ]; then
    printf 'Error: not a regular file: %s\n' "$src" >&2
    return 1
  fi

  if [ ! -r "$src" ]; then
    printf 'Error: file is not readable: %s\n' "$src" >&2
    return 1
  fi

  name=$(basename -- "$src")
  dest="/usr/local/bin/$name"

  printf 'Installing:\n'
  printf '  source:      %s\n' "$src"
  printf '  destination: %s\n' "$dest"
  printf '  owner:       root:root\n'
  printf '  mode:        0755\n'

  sudo install -o root -g root -m 0755 -- "$src" "$dest" || return $?

  printf '\nInstalled successfully:\n'
  ls -l "$dest"
}