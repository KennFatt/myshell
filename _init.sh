#!/bin/sh

# _myshell_now_ms() {
#   if [ -n "$ZSH_VERSION" ]; then
#     zmodload zsh/datetime 2>/dev/null
#     printf '%.0f\n' $((EPOCHREALTIME * 1000))
#   elif [ -n "$BASH_VERSION" ] && [ -n "${EPOCHREALTIME:-}" ]; then
#     printf '%s\n' "$((${EPOCHREALTIME/./} / 1000))"
#   else
#     perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
#   fi
# }

# _MYSHELL_INIT_START_MS="$(_myshell_now_ms)"

ENABLED_MODULES=(dev git pkg)

SCRIPT_DIR=""
if [ -n "$BASH_VERSION" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "$ZSH_VERSION" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# always load core first
[ -f "$SCRIPT_DIR/core/_init.sh" ] && . "$SCRIPT_DIR/core/_init.sh"

# load each init files in subdirs
for module in "${ENABLED_MODULES[@]}"; do
  f="$SCRIPT_DIR/$module/_init.sh"
  [ -f "$f" ] && . "$f"
done

# _MYSHELL_INIT_END_MS="$(_myshell_now_ms)"
# printf 'myshell init: %sms\n' "$((_MYSHELL_INIT_END_MS - _MYSHELL_INIT_START_MS))"
# unset _MYSHELL_INIT_START_MS _MYSHELL_INIT_END_MS
# unset -f _myshell_now_ms 2>/dev/null || unset _myshell_now_ms