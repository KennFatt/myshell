pr-commits() {
  local remote="origin"
  local branch="main"
  local limit="50"
  local do_fetch=1
  local base_ref
  local merge_base

  _pr_commits_help() {
    cat <<'EOF'
Usage:
  $0
  $0 <base-branch>
  $0 <remote> <base-branch>
  $0 --branch <base-branch>
  $0 --remote <remote>
  $0 --remote <remote> --branch <base-branch>
  $0 -r <remote> -b <base-branch>
  $0 --limit <n>
  $0 -n <n>
  $0 --no-fetch
  $0 --help

Behavior:
  - Fetches the selected remote by default for correctness
  - Does not modify your current branch, index, or working tree
  - Prints commits in current HEAD that are not in <remote>/<base-branch>
  - Shows at most the latest N commits (default: 50)

Output:
  Time | Commit hash | Author | Commit title

Defaults:
  remote = origin
  branch = feat/1.0.0
  limit  = 50

Examples:
  $0
  $0 develop
  $0 upstream develop
  $0 --remote upstream --branch develop
  $0 -r upstream -b release/2.0.0
  $0 --limit 20
  $0 --no-fetch
EOF
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        _pr_commits_help
        return 0
        ;;
      -r|--remote)
        [[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
        remote="$2"
        shift 2
        ;;
      -b|--branch)
        [[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
        branch="$2"
        shift 2
        ;;
      -n|--limit)
        [[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
        [[ "$2" =~ ^[0-9]+$ ]] || { echo "Limit must be a non-negative integer." >&2; return 1; }
        limit="$2"
        shift 2
        ;;
      --no-fetch)
        do_fetch=0
        shift
        ;;
      *)
        if [[ -z "${pos1:-}" ]]; then
          pos1="$1"
        elif [[ -z "${pos2:-}" ]]; then
          pos2="$1"
        else
          echo "Too many arguments." >&2
          _pr_commits_help >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [[ -n "${pos1:-}" && -n "${pos2:-}" ]]; then
    remote="$pos1"
    branch="$pos2"
  elif [[ -n "${pos1:-}" ]]; then
    branch="$pos1"
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a Git repository." >&2
    return 1
  fi

  if [[ "$do_fetch" -eq 1 ]]; then
    git fetch --prune "$remote" || return 1
  fi

  base_ref="${remote}/${branch}"

  if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
    echo "Base ref not found: $base_ref" >&2
    return 1
  fi

  merge_base="$(git merge-base "$base_ref" HEAD)" || return 1

  git log \
    --date=format:'%Y-%m-%d %H:%M:%S' \
    --pretty=format:'%ad | %H | %an | %s' \
    --max-count="$limit" \
    HEAD --not "$base_ref"
}
