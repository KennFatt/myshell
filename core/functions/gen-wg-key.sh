gen-wg-key() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <client-name>"
    return 1
  fi

  local name="$1"

  $wg_bin genkey | (umask 0077 && tee "${name}.key") | $wg_bin pubkey > "${name}.pub"

  echo "Generated: ${name}.key and ${name}.pub"
}
