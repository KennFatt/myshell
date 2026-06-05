#!/usr/bin/env bash

# ==========================================================
# Git Worktree Flow
# Main command: wt <branch>
# ==========================================================

_wt_usage() {
	cat <<EOF

Usage:
  wt <branch>
      Switch to an existing worktree, or create one safely.

  wt list
      List worktrees.

  wt rm <branch>
      Remove a worktree.

  wt prune
      Clean stale worktree metadata.

  wt help
      Show this help.

Description:
  wt <branch> does the safest useful thing:
    1. If worktree already exists, cd into it.
    2. If branch exists, create worktree and cd into it.
    3. If branch does not exist, create branch + worktree and cd into it.

Examples:
  wt feature-auth
  wt hotfix-login
  wt list
  wt rm feature-auth
  wt prune

EOF
}

_wt_root() {
	git rev-parse --show-toplevel 2>/dev/null
}

_wt_repo_name() {
	basename "$(_wt_root)"
}

_wt_base_dir() {
	dirname "$(_wt_root)"
}

_wt_branch_exists() {
	git show-ref --verify --quiet "refs/heads/$1"
}

_wt_worktree_path() {
	local branch="$1"
	echo "$(_wt_base_dir)/$branch"
}

_wt_existing_worktree_for_branch() {
	local branch="$1"

	git worktree list --porcelain |
		awk -v branch="refs/heads/$branch" '
      /^worktree / { path=$2 }
      /^branch / && $2 == branch { print path }
    '
}

_wt_require_repo() {
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "Error: not inside a Git repository."
		return 1
	fi
}

_wt_validate_branch_arg() {
	local branch="$1"

	if [[ -z "$branch" ]]; then
		_wt_usage
		return 1
	fi

	if [[ "$branch" == -* ]]; then
		echo "Error: branch name cannot start with '-'."
		return 1
	fi

	if [[ "$branch" == *".."* || "$branch" == *"~"* || "$branch" == *"^"* || "$branch" == *":"* || "$branch" == *"?"* || "$branch" == *"["* || "$branch" == *"\\"* ]]; then
		echo "Error: invalid branch name: $branch"
		return 1
	fi
}

wt() {
	local cmd="$1"
	local branch="$1"
	local target
	local existing

	case "$cmd" in
	"" | help | -h | --help)
		_wt_usage
		return 0
		;;

	list | ls)
		_wt_require_repo || return 1
		git worktree list
		return
		;;

	prune)
		_wt_require_repo || return 1
		git worktree prune
		return
		;;

	rm | remove)
		_wt_require_repo || return 1
		branch="$2"

		if [[ -z "$branch" ]]; then
			echo "Usage: wt rm <branch>"
			echo "Remove a worktree."
			return 1
		fi

		_wt_validate_branch_arg "$branch" || return 1

		existing="$(_wt_existing_worktree_for_branch "$branch")"

		if [[ -z "$existing" ]]; then
			target="$(_wt_worktree_path "$branch")"

			if [[ ! -d "$target" ]]; then
				echo "Error: no worktree found for branch or path: $branch"
				return 1
			fi

			existing="$target"
		fi

		echo "Removing worktree: $existing"
		git worktree remove "$existing"
		return
		;;
	esac

	_wt_require_repo || return 1
	_wt_validate_branch_arg "$branch" || return 1

	existing="$(_wt_existing_worktree_for_branch "$branch")"

	if [[ -n "$existing" ]]; then
		cd "$existing" || return 1
		echo "Entered existing worktree: $existing"
		return 0
	fi

	target="$(_wt_worktree_path "$branch")"

	if [[ -e "$target" ]]; then
		echo "Error: target path already exists but is not registered as a worktree:"
		echo "  $target"
		return 1
	fi

	if _wt_branch_exists "$branch"; then
		git worktree add "$target" "$branch" || return 1
	else
		git worktree add "$target" -b "$branch" || return 1
	fi

	cd "$target" || return 1
	echo "Entered worktree: $target"
}

if [[ -x $vscode_bin ]]; then
	wt-code() {
		wt "$1" || return 1

		$vscode_bin .
	}
fi

if [[ -x $fzf_bin ]]; then
	wt-fzf() {
		_wt_require_repo || return 1

		local target
		target="$(git worktree list | fzf | awk '{print $1}')"

		[[ -z "$target" ]] && return 1

		cd "$target" || return 1
		echo "Entered worktree: $target"
	}
fi
