if [ "$(uname)" = "Linux" ]; then
	create-systemd-service() {
		if [ $# -lt 3 ]; then
			echo "Usage: create-systemd-service <service-name> <exec-command> <memory-max> [cpu-quota] [--sandbox]"
			echo "Example: create-systemd-service myapi \"node server.js\" 512M 50% --sandbox"
			return 1
		fi

		local name="$1"
		local cmd="$2"
		local mem="$3"
		local cpu="100%"
		local sandbox="no"
		local cpu_set="no"

		shift 3
		while [ $# -gt 0 ]; do
			case "$1" in
			--sandbox)
				sandbox="yes"
				;;
			--cpu-quota)
				shift
				if [ -z "${1:-}" ]; then
					echo "Missing value for --cpu-quota" >&2
					return 1
				fi
				cpu="$1"
				cpu_set="yes"
				;;
			--cpu-quota=*)
				cpu="${1#*=}"
				cpu_set="yes"
				;;
			--*)
				echo "Unknown option: $1" >&2
				echo "Usage: create-systemd-service <service-name> <exec-command> <memory-max> [cpu-quota] [--sandbox]" >&2
				return 1
				;;
			*)
				if [ "$cpu_set" = "no" ]; then
					cpu="$1"
					cpu_set="yes"
				else
					echo "Too many arguments." >&2
					echo "Usage: create-systemd-service <service-name> <exec-command> <memory-max> [cpu-quota] [--sandbox]" >&2
					return 1
				fi
				;;
			esac
			shift
		done

		local service_path="$HOME/.config/systemd/user/${name}.service"
		mkdir -p "$HOME/.config/systemd/user"

		local workdir="$PWD"
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

		if [ -f "$envfile" ]; then
			echo "EnvironmentFile=$envfile" >>"$service_path"
		fi

		if [ "$sandbox" = "yes" ]; then
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

		cat >>"$service_path" <<EOF
[Install]
WantedBy=default.target
EOF

		$systemctl_bin --user daemon-reload
		$systemctl_bin --user enable --now "${name}.service"

		echo "✅ Service created & started: ${service_path}"
		echo "📜 View logs: journalctl --user -u ${name}.service -f"
		echo "📂 Workdir: $workdir"

		[ -f "$envfile" ] && echo "🌿 Loaded env file: $envfile"
		[ "$sandbox" = "yes" ] && echo "🛡 Sandbox enabled"
	}
fi
