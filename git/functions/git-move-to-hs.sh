git-move-to-hs() {
	b="$($git_bin branch --show-current)"

	if [ -z "$b" ]; then
		echo "Not on a branch"
		return 1
	fi

	if $git_bin show-ref --verify --quiet "refs/heads/$b-hs"; then
		echo "Branch '$b-hs' already exists"
		return 1
	fi

	$git_bin push hs "$b" &&
		$git_bin switch -c "$b-hs" &&
		$git_bin push -u hs HEAD
}
