# Common macros.
alias ls="$lsd_bin --color=auto"
alias ll='ls -alF'
alias la='ls -A'
alias lt='ls -lt'
alias lat='ls -lath'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cls='clear; ls'

alias hs="$ssh_bin homeserver"

# Time
# alias now='date +%s'
alias now="$node_bin -e 'console.log(Date.now())'"

# System info
alias sf="clear; $fastfetch_bin"
alias topmem='sudo top -o +%MEM'
alias inxi="$inxi_bin -Fxz"

# Network monitoring
alias lsport="sudo $lsof_bin -i -P -n"

# User level application
alias garage="$docker_bin exec -it garage-s3_garage_1 /garage"

if [[ -f $ufw_bin ]]; then
	alias ufw-status="sudo $ufw_bin status verbose"
	alias ufw-reload="sudo $ufw_bin reload"
	alias ufw-list="sudo $ufw_bin status numbered"
	alias ufw-ls="sudo $ufw_bin status numbered"
	alias ufw-log="sudo $less_bin -f /var/log/ufw.log"
	alias ufw-allow="sudo $ufw_bin allow"
	alias ufw-deny="sudo $ufw_bin deny"
	alias ufw-allow-from="sudo $ufw_bin allow from"
	alias ufw-delete="sudo $ufw_bin delete"
	alias ufw-del="sudo $ufw_bin delete"
	alias ufw-rm="sudo $ufw_bin delete"
	alias ufw-apps="sudo $ufw_bin app list"
fi

if [ "$(uname)" = "Linux" ]; then
	# System info
	alias cpuinfo="$watch_bin -n1 'cat /proc/cpuinfo | grep MHz'"
	alias meminfo='watch -n1 "awk '\'' 
/MemTotal/ { total=\$2 }
/(Cached|Buffers|MemAvailable|MemTotal|SwapTotal|SwapFree)/ {
  printf \"%-15s %8.1f MB %7.2f%%\\n\", \$1, \$2/1024, (\$2/total)*100
}
'\'' /proc/meminfo | column -t"'

	# I/O Monitoring
	alias iotop='sudo iotop'

	# SFTP user management
	alias user-create='f() { sudo useradd -m -s /usr/sbin/nologin "$1" && sudo passwd "$1"; }; f'
	alias user-remove='f() { sudo deluser --remove-home "$1"; }; f'
	alias user-list='grep "/nologin" /etc/passwd | cut -d: -f1'
fi

if [ "$(uname)" = "Darwin" ]; then
	# Quickly fix local network routing issues
	alias flushdns='sudo route flush && sudo ifconfig en0 down && sudo ifconfig en0 up && sudo ipconfig set en0 DHCP && echo "✅ Network routes flushed and renewed."'
fi
