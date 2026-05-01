git-init-hs() {
	if [ -z "$1" ]; then
		echo "Usage: git-init-hs <homeserver-git-url>"
		return 1
	fi

	if git remote get-url hs >/dev/null 2>&1; then
		echo "Remote 'hs' already exists:"
		git remote get-url hs
		return 0
	fi

	git remote add hs "$1"
	git remote -v
}
