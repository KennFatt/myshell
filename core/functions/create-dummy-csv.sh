create-dummy-csv() {
	local filename=""
	local size_mib=1

	if [[ $# -lt 1 ]]; then
		echo "Usage: create-dummy-csv <filename> [--size MiB]"
		return 1
	fi

	filename="$1"
	shift

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--size)
			shift
			if [[ -z "$1" || ! "$1" =~ ^[0-9]+$ ]]; then
				echo "Error: --size must be followed by an integer MiB value"
				return 1
			fi
			size_mib="$1"
			;;
		*)
			echo "Error: unknown argument: $1"
			echo "Usage: create-dummy-csv <filename> [--size MiB]"
			return 1
			;;
		esac
		shift
	done

	local target_bytes=$((size_mib * 1024 * 1024))

	awk -v target="$target_bytes" '
    BEGIN {
      header = "id,name,email,value,created_at\n"
      printf "%s", header
      bytes = length(header)
      i = 1

      while (bytes < target) {
        line = i ",user_" i ",user_" i "@example.com," (i % 100000) ",2026-04-20T00:00:00Z\n"
        printf "%s", line
        bytes += length(line)
        i++
      }
    }
  ' >"$filename"

	echo "Created $filename (~${size_mib} MiB)"
}
