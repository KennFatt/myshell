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
