git-apply-hs() {
	hs_branch="$($git_bin branch --show-current)"
	work_branch="${hs_branch%-hs}"

	if [ "$hs_branch" = "$work_branch" ]; then
		echo "You must run this from a *-hs branch"
		return 1
	fi

	$git_bin switch "$work_branch" &&
		$git_bin merge --squash "$hs_branch" &&
		$git_bin restore --staged .
}
