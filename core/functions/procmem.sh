function procmem() {
	if [[ -z $1 ]]; then
		echo "Usage: procmem <process_name>"
		return
	fi

	echo "[INFO] Memory in KiB:"
	$ps_bin -eo pid,rss,comm | grep -i $1
}
