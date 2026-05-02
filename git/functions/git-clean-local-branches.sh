git-clean-local-branches() {
  remote="${1:-origin}"

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a git repository."
    return 1
  }

  git remote get-url "$remote" >/dev/null 2>&1 || {
    echo "Remote '$remote' does not exist."
    return 1
  }

  git fetch "$remote" --prune || {
    echo "Failed to fetch remote '$remote'."
    return 1
  }

  current_branch="$(git branch --show-current 2>/dev/null)"

  git for-each-ref --format='%(refname:short)' refs/heads/ |
  while IFS= read -r branch; do
    # Never delete the currently checked-out branch
    if [ "$branch" = "$current_branch" ]; then
      continue
    fi

    # Compare local branch name against remote branch with same name
    if ! git show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
      printf "Remove local branch '%s'? [y/N] " "$branch"
      IFS= read -r answer

      case "$answer" in
        [yY]|[yY][eE][sS])
          if git branch -d "$branch"; then
            echo "Deleted '$branch'."
          else
            echo "Branch '$branch' is not fully merged."
            printf "Force delete '%s'? [y/N] " "$branch"
            IFS= read -r force_answer

            case "$force_answer" in
              [yY]|[yY][eE][sS])
                git branch -D "$branch"
                ;;
              *)
                echo "Skipped '$branch'."
                ;;
            esac
          fi
          ;;
        *)
          echo "Skipped '$branch'."
          ;;
      esac
    fi
  done
}