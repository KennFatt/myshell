function ipgeoloc() {
	curl https://api.ipbase.com/v1/json/$1 -s | jq
}
