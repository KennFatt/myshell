# Common macros.
alias ls='lsd --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias lt='ls -lt'
alias lat='ls -lath'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cls='clear; ls'

# Time
alias now='date +%s'

# System info
alias sf='clear; fastfetch'
alias topmem='sudo top -o +%MEM'

# Network monitoring
alias iftop='sudo iftop -i eth0 -B'
alias lsport='sudo lsof -i -P -n'

if [[ -f $ufw_bin ]]; then
	alias ufw-status='sudo ufw status verbose'
	alias ufw-reload='sudo ufw reload'
	alias ufw-list='sudo ufw status numbered'
	alias ufw-ls='sudo ufw status numbered'
	alias ufw-log='sudo less -f /var/log/ufw.log'
	alias ufw-allow='sudo ufw allow'
	alias ufw-deny='sudo ufw deny'
	alias ufw-allow-from='sudo ufw allow from'
	alias ufw-delete='sudo ufw delete'
	alias ufw-del='sudo ufw delete'
	alias ufw-rm='sudo ufw delete'
	alias ufw-apps='sudo ufw app list'
fi

if [ "$(uname)" = "Linux" ]; then
	# System info
	alias cpuinfo="watch -n1 'cat /proc/cpuinfo | grep MHz'"
	alias meminfo="watch -n1 'free -mh'"

	# I/O Monitoring
	alias iotop='sudo iotop'
fi

if [ "$(uname)" = "Darwin" ]; then
	# Quickly fix local network routing issues
	alias flushdns='sudo route flush && sudo ifconfig en0 down && sudo ifconfig en0 up && sudo ipconfig set en0 DHCP && echo "✅ Network routes flushed and renewed."'
fi
