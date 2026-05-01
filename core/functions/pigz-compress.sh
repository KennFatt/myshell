if [[ -x $pigz_bin ]]; then
	function pigz-compress() {
		if [[ -z $1 || -z $2 ]]; then
			echo "Usage: pigz-compress <folder> <output.tar.gz>"
			return
		fi

		$tar_bin cf - $1 | $pigz_bin >$2
	}
fi
