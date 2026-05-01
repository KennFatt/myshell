if [[ -x $pigz_bin ]]; then
	function pigz-decompress() {
		$pigz_bin -dc $1 | $tar_bin xf -
	}
fi
