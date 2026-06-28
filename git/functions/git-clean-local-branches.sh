git-clean-local-branches() {
  remote="${1:-origin}"

  $git_bin rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a git repository."
    return 1
  }

  $git_bin remote get-url "$remote" >/dev/null 2>&1 || {
    echo "Remote '$remote' does not exist."
    return 1
  }

  $git_bin fetch "$remote" --prune || {
    echo "Failed to fetch remote '$remote'."
    return 1
  }

  current_branch="$($git_bin branch --show-current 2>/dev/null)"

  $git_bin for-each-ref --format='%(refname:short)' refs/heads/ |
  while IFS= read -r branch; do
    if [ "$branch" = "$current_branch" ]; then
      continue
    fi

    if ! $git_bin show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
      printf "Remove local branch '%s'? [y/N] " "$branch" > /dev/tty
      IFS= read -r answer < /dev/tty

      case "$answer" in
        [yY]|[yY][eE][sS])
          if $git_bin branch -d "$branch"; then
            echo "Deleted '$branch'."
          else
            echo "Branch '$branch' is not fully merged."
            printf "Force delete '%s'? [y/N] " "$branch" > /dev/tty
            IFS= read -r force_answer < /dev/tty

            case "$force_answer" in
              [yY]|[yY][eE][sS])
                $git_bin branch -D "$branch"
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