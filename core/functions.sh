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

		cat > "$service_path" <<EOF
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
			echo "EnvironmentFile=$envfile" >> "$service_path"
		fi

		# Optional Sandbox
		if [[ "$sandbox" == "yes" ]]; then
			cat >> "$service_path" <<EOF
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
		cat >> "$service_path" <<EOF
[Install]
WantedBy=default.target
EOF

		systemctl --user daemon-reload
		systemctl --user enable --now "${name}.service"

		# echo "✅ Service created & started: ${name}.service"
		echo "✅ Service created & started: ${service_path}"
		echo "📜 View logs: journalctl --user -u ${name}.service -f"
		echo "📂 Workdir: $workdir"
		# echo "✨ Dont forget to:"
		# echo "systemctl --user daemon-reload"
		# echo "systemctl --user enable --now \"${name}.service\""

		[[ -f "$envfile" ]] && echo "🌿 Loaded env file: $envfile"
		[[ "$sandbox" == "yes" ]] && echo "🛡 Sandbox enabled"
	}
fi
