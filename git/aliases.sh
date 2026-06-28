alias git-most-active="$git_bin log --format=format: --name-only --since=12.month| egrep -v '^$' | sort | uniq -c | sort -nr | head -50"
alias git-uncommit="$git_bin reset --soft HEAD~1"
alias git-get-head="$git_bin rev-parse HEAD"
alias git-staged="$git_bin diff --name-only --cached"