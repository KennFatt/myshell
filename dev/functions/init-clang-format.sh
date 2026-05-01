if [[ -f ~/.clang-format/.clang-format ]]; then
	function init-clang-format() {
		cp ~/.clang-format/.clang-format .
	}
fi
