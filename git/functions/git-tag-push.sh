#!/bin/sh

# Create a tag and push it to a remote in one step.
# Lightweight by default; a message makes it annotated. Remote defaults to origin.
git-tag-push() {
	tag=""
	message=""
	remote="origin"

	_git_tag_push_usage() {
		echo "Usage: git-tag-push <tag> [message] [-r remote]" >&2
		echo "  git-tag-push v0.0.1                        lightweight tag, pushed to origin" >&2
		echo "  git-tag-push v0.0.1 \"release 0.0.1\"         annotated tag, pushed to origin" >&2
		echo "  git-tag-push v0.0.1 -r upstream            pushed to upstream instead" >&2
	}

	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				_git_tag_push_usage
				return 1
				;;
			-r|--remote)
				if [ -z "${2:-}" ]; then
					echo "Missing value for $1" >&2
					return 1
				fi
				remote="$2"
				shift 2
				;;
			--)
				shift
				break
				;;
			*)
				if [ -z "$tag" ]; then
					tag="$1"
				elif [ -z "$message" ]; then
					message="$1"
				else
					echo "Too many arguments." >&2
					_git_tag_push_usage
					return 1
				fi
				shift
				;;
		esac
	done

	if [ -z "$tag" ]; then
		_git_tag_push_usage
		return 1
	fi

	if ! $git_bin rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "Not inside a Git repository." >&2
		return 1
	fi

	if $git_bin rev-parse --verify --quiet "refs/tags/$tag" >/dev/null 2>&1; then
		echo "Tag already exists locally: $tag" >&2
		return 1
	fi

	if [ -n "$message" ]; then
		$git_bin tag -a "$tag" -m "$message" || return 1
	else
		$git_bin tag "$tag" || return 1
	fi

	if ! $git_bin push "$remote" "$tag"; then
		echo "Push to $remote failed; removing local tag: $tag" >&2
		$git_bin tag -d "$tag" >/dev/null
		return 1
	fi
}
