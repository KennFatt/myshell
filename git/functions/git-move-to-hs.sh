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
