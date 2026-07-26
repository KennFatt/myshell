export MYSPACE_HOME=$HOME/myspace
export CODEX_HOME=$HOME/.codex
export MANLY_ROOT=$MYSPACE_HOME/memories
export FJ_FALLBACK_HOST=https://git.kennfatt.dev

if [[ -x $cot_bin ]]; then
	export EDITOR=$cot_bin
	export VISUAL=$cot_bin
fi
