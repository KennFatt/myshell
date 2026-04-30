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

	if [ -z "$b" ]; then
		echo "Not on a branch"
		return 1
	fi

	if git show-ref --verify --quiet "refs/heads/$b-hs"; then
		echo "Branch '$b-hs' already exists"
		return 1
	fi

	git push hs "$b" &&
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

git-cleanup-hs() {
	current="$(git branch --show-current)"

	if [ -z "$current" ]; then
		echo "Not on a branch"
		return 1
	fi

	if [[ "$current" == *-hs ]]; then
		hs_branch="$current"
		work_branch="${current%-hs}"
		git switch "$work_branch" || return 1
	else
		work_branch="$current"
		hs_branch="$current-hs"
	fi

	echo "Cleaning:"
	echo "  local branch:  $hs_branch"
	echo "  remote branch: hs/$hs_branch"
	echo "  remote branch: hs/$work_branch"
	echo

	printf "Continue? [y/N] "
	read -r confirm
	if [ "$confirm" != "y" ]; then
		echo "Cancelled"
		return 1
	fi

	git branch -D "$hs_branch" 2>/dev/null || true
	git push hs --delete "$hs_branch" 2>/dev/null || true
	git push hs --delete "$work_branch" 2>/dev/null || true

	echo "HS cleanup done."
}
