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
#   1. Existing worktree? -> enter it, open in VS Code
#   2. Existing branch?   -> create worktree + copy local changes + enter it, open in VS Code
#   3. New branch?        -> create branch + worktree + copy local changes + enter it, open in VS Code
#
# ==========================================================

_wt_help() {
	cat <<'EOF'

Git Worktree Commands

  wt <branch>
      Enter or create a worktree (copies unstaged tracked + untracked files when creating) and opens it in VS Code.

  wt list
      List worktrees.

  wt rm <branch>
      Remove a worktree.

  wt prune
      Clean stale worktree metadata.

  wt help
      Show help.

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
	$git_bin rev-parse --is-inside-work-tree >/dev/null 2>&1
}

_wt_repo_root() {
	$git_bin rev-parse --show-toplevel
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
	$git_bin show-ref --verify --quiet "refs/heads/$1"
}

_wt_copy_untracked_files() {
	local target="$1"
	local file

	$git_bin ls-files --others --exclude-standard -z |
	while IFS= read -r -d '' file; do
		[[ -e "$file" ]] || continue

		mkdir -p "$target/$(dirname "$file")" || return 1
		cp -R "$file" "$target/$file" || return 1
		echo "Copied untracked file: $file"
	done
}

_wt_apply_unstaged_tracked_changes() {
	local target="$1"
	local patch_file

	patch_file="$(mktemp)" || return 1
	$git_bin diff --binary --no-ext-diff >"$patch_file"

	if [[ ! -s "$patch_file" ]]; then
		rm -f "$patch_file"
		return 0
	fi

	(
		cd "$target" || exit 1
		$git_bin apply --index --reject "$patch_file" && $git_bin reset
	) || {
		rm -f "$patch_file"
		return 1
	}

	rm -f "$patch_file"
}

_wt_find_worktree() {
	local branch="$1"

	$git_bin worktree list --porcelain |
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

	$git_bin check-ref-format --branch "$branch" >/dev/null 2>&1
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

		$git_bin worktree list
		return
		;;

	prune)
		_wt_require_repo || {
			echo "Not inside a git repository."
			return 1
		}

		$git_bin worktree prune
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
		if ! $git_bin worktree remove "$existing" 2>&1; then
			printf "Force remove? [Y/n] "
			read -r reply
			case "${reply:-Y}" in
				[Yy]*) $git_bin worktree remove --force "$existing" ;;
				*) echo "Aborted."; return 1 ;;
			esac
		fi
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
		if [[ -x $vscode_bin ]]; then
			$vscode_bin .
		fi
		return 0
	fi

	local target

	target="$(_wt_worktree_path "$branch")"

	if [[ -e "$target" ]]; then
		echo "Path already exists: $target"
		return 1
	fi

	if _wt_branch_exists "$branch"; then
		$git_bin worktree add "$target" "$branch" || return 1
	else
		$git_bin worktree add "$target" -b "$branch" || return 1
	fi

	_wt_apply_unstaged_tracked_changes "$target" || return 1
	_wt_copy_untracked_files "$target" || return 1

	cd "$target" || return 1
	echo "Entered worktree: $target"
	if [[ -x $vscode_bin ]]; then
		$vscode_bin .
	fi
}

if [[ -x $vscode_bin ]]; then
	# Backward compat: wt-code is now the same as wt.
	wt-code() {
		wt "$@"
	}
fi

if [[ -x $fzf_bin ]]; then
	wt-fzf() {
		_wt_require_repo || return 1

		local target
		target="$($git_bin worktree list | $fzf_bin | awk '{print $1}')"

		[[ -z "$target" ]] && return 1

		cd "$target" || return 1
		echo "Entered worktree: $target"
		if [[ -x $vscode_bin ]]; then
			$vscode_bin .
		fi
	}
fi
