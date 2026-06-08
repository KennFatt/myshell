#!/usr/bin/env bash

# ==========================================================
# Git Worktree Flow
# ==========================================================
#
# Main command:
#
#   wt <branch>
#
# Examples:
#
#   wt feat/auth
#   wt fix/login-bug
#   wt release/v2
#
# Behavior:
#
#   1. Existing worktree? -> enter it
#   2. Existing branch?   -> create worktree + enter it
#   3. New branch?        -> create branch + worktree + enter it
#
# ==========================================================

_wt_help() {
	cat <<'EOF'

Git Worktree Commands

  wt <branch>
      Enter existing worktree or create one.

  wt list
      List worktrees.

  wt rm <branch>
      Remove a worktree.

  wt prune
      Clean stale worktree metadata.

  wt help
      Show help.

  wt-code <branch>
      Open a worktree in VS Code.

  wt-fzf
      Interactive worktree switcher.

Examples

  wt feat/auth
  wt fix/login-bug
  wt release/v2

  wt list
  wt rm feat/auth
  wt prune

EOF
}

_wt_require_repo() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

_wt_repo_root() {
	git rev-parse --show-toplevel
}

_wt_parent_dir() {
	dirname "$(_wt_repo_root)"
}

# feat/auth -> wt-feat-auth
_wt_dir_name() {
	local branch="$1"
	echo "wt-${branch//\//-}"
}

_wt_worktree_path() {
	local branch="$1"
	echo "$(_wt_parent_dir)/$(_wt_dir_name "$branch")"
}

_wt_branch_exists() {
	git show-ref --verify --quiet "refs/heads/$1"
}

_wt_find_worktree() {
	local branch="$1"

	git worktree list --porcelain |
		awk -v target="refs/heads/$branch" '
    /^worktree / { path=$2 }
    /^branch / {
      if ($2 == target) {
        print path
      }
    }
  '
}

_wt_validate_branch() {
	local branch="$1"

	if [[ -z "$branch" ]]; then
		_wt_help
		return 1
	fi

	git check-ref-format --branch "$branch" >/dev/null 2>&1
}

wt() {

	local cmd="$1"

	case "$cmd" in

	"" | -h | --help | help)
		_wt_help
		return 0
		;;

	list | ls)
		_wt_require_repo || {
			echo "Not inside a git repository."
			return 1
		}

		git worktree list
		return
		;;

	prune)
		_wt_require_repo || {
			echo "Not inside a git repository."
			return 1
		}

		git worktree prune
		return
		;;

	rm | remove)

		_wt_require_repo || {
			echo "Not inside a git repository."
			return 1
		}

		local branch="$2"

		if [[ -z "$branch" ]]; then
			echo "Usage: wt rm <branch>"
			echo
			echo "Example:"
			echo "  wt rm feat/auth"
			return 1
		fi

		local existing

		existing="$(_wt_find_worktree "$branch")"

		if [[ -z "$existing" ]]; then
			existing="$(_wt_worktree_path "$branch")"
		fi

		if [[ ! -d "$existing" ]]; then
			echo "Worktree not found: $branch"
			return 1
		fi

		echo "Removing: $existing"
		git worktree remove "$existing"
		return
		;;
	esac

	_wt_require_repo || {
		echo "Not inside a git repository."
		return 1
	}

	local branch="$1"

	_wt_validate_branch "$branch" || {
		echo "Invalid branch name."
		return 1
	}

	local existing

	existing="$(_wt_find_worktree "$branch")"

	if [[ -n "$existing" ]]; then
		cd "$existing" || return 1
		echo "Entered: $existing"
		return 0
	fi

	local target

	target="$(_wt_worktree_path "$branch")"

	if [[ -e "$target" ]]; then
		echo "Path already exists: $target"
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
