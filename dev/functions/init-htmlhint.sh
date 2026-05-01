if [[ -d ~/.htmlhint ]]; then
	function init-htmlhint() {
		cp ~/.htmlhint/.htmlhintrc .
	}
fi
