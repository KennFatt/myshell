sync-config-git() {
	local repos=(
		"$HOME/.myshell"
		"$HOME/.pi"
	)

	local failed=()
	local repo
	local pull_status

	for repo in "${repos[@]}"; do
		echo "----------------------------------------"
		echo "Updating: $repo"

		if [[ ! -d "$repo" ]]; then
			echo "FAIL: Directory does not exist: $repo"
			failed+=("$repo — directory does not exist")
			continue
		fi

		if [[ ! -d "$repo/.git" ]]; then
			echo "FAIL: Not a git repository: $repo"
			failed+=("$repo — not a git repository")
			continue
		fi

		(
			cd "$repo" || exit 1
			git pull
		)

		pull_status=$?

		if [[ $pull_status -eq 0 ]]; then
			echo "OK: $repo"
		else
			echo "FAIL: git pull failed in $repo"
			failed+=("$repo — git pull failed with exit code $pull_status")
		fi
	done

	echo "----------------------------------------"

	if [[ ${#failed[@]} -eq 0 ]]; then
		echo "All repositories updated successfully."
		return 0
	else
		echo "Some repositories failed:"
		for failure in "${failed[@]}"; do
			echo " - $failure"
		done
		return 1
	fi
}
