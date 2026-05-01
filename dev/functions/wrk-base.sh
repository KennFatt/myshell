function wrk-base() {
	if [[ -z $1 || -z $2 ]]; then
		echo "Usage: wrk-base <conn: int> <url: string>"
		echo "Example: wrk-base 100 http://localhost:3030/v1/healthz"
		return
	fi

	$wrk_bin -t4 -d10s -c$1 --latency $2
}
