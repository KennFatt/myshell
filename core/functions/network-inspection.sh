# Investigate what an IP is doing on this machine
ipcheck() {
  if [ -z "$1" ]; then
    echo "Usage: ipcheck <IP>"
    return 1
  fi

  IP="$1"

  echo "=== Active connections involving $IP ==="
  sudo ss -tunap | grep --color=always "$IP" || echo "No active ss connections found."

  echo
  echo "=== Recent auth log entries ==="
  sudo grep "$IP" /var/log/auth.log 2>/dev/null | tail -50 || echo "No /var/log/auth.log matches."

  echo
  echo "=== Recent syslog entries ==="
  sudo grep "$IP" /var/log/syslog 2>/dev/null | tail -50 || echo "No /var/log/syslog matches."

  echo
  echo "=== UFW log entries ==="
  sudo grep "$IP" /var/log/ufw.log 2>/dev/null | tail -50 || echo "No /var/log/ufw.log matches."

  echo
  echo "=== Fail2ban matches ==="
  sudo fail2ban-client banned 2>/dev/null | grep "$IP" || echo "IP is not currently shown as banned by fail2ban."

  echo
  echo "=== Reverse DNS ==="
  dig -x "$IP" +short 2>/dev/null || nslookup "$IP" 2>/dev/null

  echo
  echo "=== Caddy log entries ==="
  sudo journalctl -u caddy --since "24 hours ago" --no-pager 2>/dev/null | grep --color=always "$IP" | tail -50 || echo "No Caddy journal matches."

  sudo grep -h "$IP" \
    /var/log/caddy/*.log \
    /var/log/caddy/*/*.log \
    /var/log/caddy/access.log* \
    /var/log/caddy/error.log* \
    2>/dev/null | tail -50 || true
}

# Watch live connections for an IP
ipwatch() {
  if [ -z "$1" ]; then
    echo "Usage: ipwatch <IP>"
    return 1
  fi

  watch -n 1 "sudo ss -tunap | grep '$1' || true"
}

# Block an IP with UFW
ipban() {
  if [ -z "$1" ]; then
    echo "Usage: ipban <IP>"
    return 1
  fi

  sudo ufw deny from "$1"
  sudo ufw reload
  echo "Blocked $1 with UFW."
}

# Unblock an IP from UFW
ipunban() {
  if [ -z "$1" ]; then
    echo "Usage: ipunban <IP>"
    return 1
  fi

  sudo ufw delete deny from "$1"
  sudo ufw reload
  echo "Removed UFW deny rule for $1."
}

# Show all currently banned IPs from fail2ban
f2blist() {
  sudo fail2ban-client banned
}

# Show detailed fail2ban status
f2bstatus() {
  sudo fail2ban-client status
}

# Show one fail2ban jail status
f2bjail() {
  if [ -z "$1" ]; then
    echo "Usage: f2bjail <jail>"
    echo "Example: f2bjail sshd"
    return 1
  fi

  sudo fail2ban-client status "$1"
}

# Manually ban IP in a fail2ban jail
f2bban() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: f2bban <jail> <IP>"
    echo "Example: f2bban sshd 1.2.3.4"
    return 1
  fi

  sudo fail2ban-client set "$1" banip "$2"
}

# Manually unban IP from a fail2ban jail
f2bunban() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: f2bunban <jail> <IP>"
    echo "Example: f2bunban sshd 1.2.3.4"
    return 1
  fi

  sudo fail2ban-client set "$1" unbanip "$2"
}

# Check Caddy logs for an IP
ipcaddy() {
  if [ -z "$1" ]; then
    echo "Usage: ipcaddy <IP>"
    return 1
  fi

  IP="$1"

  echo "=== Caddy logs via journalctl ==="
  sudo journalctl -u caddy --since "24 hours ago" --no-pager 2>/dev/null | grep --color=always "$IP" | tail -100 || echo "No Caddy journal matches."

  echo
  echo "=== Common Caddy log files ==="
  sudo grep -h "$IP" \
    /var/log/caddy/*.log \
    /var/log/caddy/*/*.log \
    /var/log/caddy/access.log* \
    /var/log/caddy/error.log* \
    2>/dev/null | tail -100 || echo "No Caddy file log matches."

  echo
  echo "=== Caddy config references to logs ==="
  sudo grep -RniE "log|output|access|error" /etc/caddy 2>/dev/null | head -100 || echo "No obvious Caddy log config found."
}