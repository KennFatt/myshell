function ipgeoloc() {
	curl https://api.ipbase.com/v1/json/$1 -s | jq
}

if [[ -x $pigz_bin ]]; then
	function pigz-compress() {
		if [[ -z $1 || -z $2 ]]; then
			echo "Usage: pigz-compress <folder> <output.tar.gz>"
			return
		fi

		$tar_bin cf - $1 | $pigz_bin >$2
	}

	function pigz-decompress() {
		$pigz_bin -dc $1 | $tar_bin xf -
	}
fi

function procmem() {
	if [[ -z $1 ]]; then
		echo "Usage: procmem <process_name>"
		return
	fi

	echo "[INFO] Memory in KiB:"
	$ps_bin -eo pid,rss,comm | grep -i $1
}

mytemplate() {
	local templates_dir="$MYSPACE_HOME/templates"

	if [ ! -d "$templates_dir" ]; then
		echo "Error: templates directory not found: $templates_dir" >&2
		return 1
	fi

	local usage="Usage:
  mytemplate --list
  mytemplate <template_name>
  mytemplate <template_name> <new_name>"

	if [ $# -eq 0 ]; then
		echo "$usage" >&2
		return 1
	fi

	if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
		echo "Available templates in: $templates_dir"
		ls -1h "$templates_dir"
		return 0
	fi

	local src_name="$1"
	local dst_name="${2:-$1}"
	local src_path="$templates_dir/$src_name"
	local dst_path="./$dst_name"

	if [ ! -e "$src_path" ]; then
		echo "Error: template not found: $src_name" >&2
		return 1
	fi

	if [ -e "$dst_path" ]; then
		echo "Error: destination already exists: $dst_name" >&2
		return 1
	fi

	cp -R "$src_path" "$dst_path"

	if [ $? -ne 0 ]; then
		echo "Error: failed to copy template." >&2
		return 1
	fi

	echo "Copied '$src_name' -> '$dst_name'"
}

if [ "$(uname)" = "Linux" ]; then
	function service-dependencies() {
		if [[ -z $1 ]]; then
			echo "Usage: service-dependencies <service_name>"
			echo "Example: service-dependencies libvirtd"
			return
		fi

		grep "Wants=${1}" /etc/systemd/system/*/*
	}

	genservice() {
		if [ $# -lt 3 ]; then
			echo "Usage: genservice <service-name> <exec-command> <memory-max> [cpu-quota] [--sandbox]"
			echo "Example: genservice myapi \"node server.js\" 512M 50% --sandbox"
			return 1
		fi

		local name="$1"
		local cmd="$2"
		local mem="$3"
		local cpu="${4:-100%}"

		local sandbox="no"
		if [[ "$*" == *"--sandbox"* ]]; then
			sandbox="yes"
		fi

		local service_path="$HOME/.config/systemd/user/${name}.service"
		mkdir -p "$HOME/.config/systemd/user"

		local workdir
		workdir=$(dirname "$(realpath "$cmd" 2>/dev/null)")
		local envfile="$workdir/.env"

		cat >"$service_path" <<EOF
[Unit]
Description=$name service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$cmd
WorkingDirectory=$workdir

# Restart behavior
Restart=on-failure
RestartSec=3
OOMPolicy=kill

# Resource limits
MemoryMax=$mem
CPUQuota=$cpu

# Logging (journal + cockpit)
StandardOutput=journal
StandardError=journal

EOF

		# Auto-load .env if exists
		if [[ -f "$envfile" ]]; then
			echo "EnvironmentFile=$envfile" >>"$service_path"
		fi

		# Optional Sandbox
		if [[ "$sandbox" == "yes" ]]; then
			cat >>"$service_path" <<EOF
# Sandboxing
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectKernelModules=true
EOF
		fi

		# Finish file
		cat >>"$service_path" <<EOF
[Install]
WantedBy=default.target
EOF

		systemctl --user daemon-reload
		systemctl --user enable --now "${name}.service"

		echo "✅ Service created & started: ${service_path}"
		echo "📜 View logs: journalctl --user -u ${name}.service -f"
		echo "📂 Workdir: $workdir"

		[[ -f "$envfile" ]] && echo "🌿 Loaded env file: $envfile"
		[[ "$sandbox" == "yes" ]] && echo "🛡 Sandbox enabled"
	}
fi

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
