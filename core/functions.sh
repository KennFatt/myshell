function ipgeoloc() {
	curl https://api.ipbase.com/v1/json/$1 -s | jq
}

if [[ -x $pigz_bin ]]; then
	function pigz-compress() {
		if [[ -z $1 || -z $2 ]]; then
			echo "Usage: pigz-compress <folder> <output.tar.gz>"
			return
		fi

		$tar_bin cf - $1 | $pigz_bin >$2
	}

	function pigz-decompress() {
		$pigz_bin -dc $1 | $tar_bin xf -
	}
fi

function procmem() {
	if [[ -z $1 ]]; then
		echo "Usage: procmem <process_name>"
		return
	fi

	echo "[INFO] Memory in KiB:"
	$ps_bin -eo pid,rss,comm | grep -i $1
}

if [ "$(uname)" = "Linux" ]; then
	function service-dependencies() {
		if [[ -z $1 ]]; then
			echo "Usage: service-dependencies <service_name>"
			echo "Example: service-dependencies libvirtd"
			return
		fi

		grep "Wants=${1}" /etc/systemd/system/*/*
	}
fi
