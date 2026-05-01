if [[ -d ~/.prettier ]]; then
	function init-prettier() {
		cp -a ~/.prettier/. .
	}
fi
