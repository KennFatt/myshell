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
