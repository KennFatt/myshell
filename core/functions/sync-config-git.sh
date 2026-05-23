sync-config-git() {
	local repos=(
		"$HOME/.myshell"
		"$HOME/.pi"
		"$MYSPACE_HOME"
	)

	local tmpdir
	tmpdir="$(mktemp -d)" || {
		echo "FAIL: Could not create temp dir"
		return 1
	}

	local pids=()
	local repo
	local i=0

	for repo in "${repos[@]}"; do
		(
			local output_file="$tmpdir/$i.out"
			local status_file="$tmpdir/$i.status"

			{
				echo "----------------------------------------"
				echo "Updating: $repo"

				if [[ ! -d "$repo" ]]; then
					echo "FAIL: Directory does not exist: $repo"
					echo "1" >"$status_file"
					exit 0
				fi

				if [[ ! -d "$repo/.git" ]]; then
					echo "FAIL: Not a git repository: $repo"
					echo "1" >"$status_file"
					exit 0
				fi

				cd "$repo" || {
					echo "FAIL: Could not cd into: $repo"
					echo "1" >"$status_file"
					exit 0
				}

				git pull --recurse-submodules
				local pull_status=$?

				if [[ $pull_status -eq 0 ]]; then
					echo "OK: $repo"
					echo "0" >"$status_file"
				else
					echo "FAIL: git pull failed in $repo with exit code $pull_status"
					echo "1" >"$status_file"
				fi
			} >"$output_file" 2>&1
		) &

		pids+=($!)
		i=$((i + 1))
	done

	local pid
	for pid in "${pids[@]}"; do
		wait "$pid"
	done

	local failed=0
	local status_file
	local output_file

	for ((i = 0; i < ${#repos[@]}; i++)); do
		output_file="$tmpdir/$i.out"
		status_file="$tmpdir/$i.status"

		cat "$output_file"

		if [[ ! -f "$status_file" ]] || [[ "$(cat "$status_file")" != "0" ]]; then
			failed=1
		fi
	done

	rm -rf "$tmpdir"

	echo "----------------------------------------"

	if [[ $failed -eq 0 ]]; then
		echo "All repositories updated successfully."
		return 0
	else
		echo "Some repositories failed."
		return 1
	fi
}
