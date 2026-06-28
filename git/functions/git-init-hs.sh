git-init-hs() {
	if [ -z "$1" ]; then
		echo "Usage: git-init-hs <homeserver-git-url>"
		return 1
	fi

	if $git_bin remote get-url hs >/dev/null 2>&1; then
		echo "Remote 'hs' already exists:"
		$git_bin remote get-url hs
		return 0
	fi

	$git_bin remote add hs "$1"
	$git_bin remote -v
}
