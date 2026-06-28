ipgeoloc() {
	$curl_bin "https://api.ipbase.com/v1/json/$1" -s | $jq_bin
}
