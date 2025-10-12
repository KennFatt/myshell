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
