function git-switch-kennfatt() {
	git config user.name KennFatt
	git config user.email kennfatt@gmail.com
}

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

git-move-to-hs() {
	b="$(git branch --show-current)"
	git switch -c "$b-hs" &&
		git push -u hs HEAD
}

git-apply-hs() {
	hs_branch="$(git branch --show-current)"
	work_branch="${hs_branch%-hs}"

	if [ "$hs_branch" = "$work_branch" ]; then
		echo "You must run this from a *-hs branch"
		return 1
	fi

	git switch "$work_branch" &&
		git merge --squash "$hs_branch" &&
		git restore --staged .
}
