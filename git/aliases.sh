alias git-most-active="git log --format=format: --name-only --since=12.month| egrep -v '^$' | sort | uniq -c | sort -nr | head -50"
alias git-uncommit="git reset --soft HEAD~1"
alias git-get-head="git rev-parse HEAD"
