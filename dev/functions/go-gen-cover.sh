if [ "$(uname)" = "Linux" ]; then
	function go-gen-cover() {
		# Check dependencies
		if ! type xargs &>/dev/null; then
			echo "error: 'xargs' command is missing"
			return 1
		fi

		if [ -z "$go_bin" ]; then
			echo "error: 'go' command is missing"
			return 1
		fi

		module_name=$1
		if [ -z "$module_name" ]; then
			echo "usage: $0 <module_name_pattern>"
			return 1
		fi

		# temporary output
		tDir="/tmp/go-gen-cover"
		rm -rf $tDir
		mkdir -p $tDir

		t="$tDir/go-cover.$$.tmp"

		# run the test and generate the coverage > $t.html
		$go_bin list ./... | grep $module_name | xargs $go_bin test -coverprofile=$t && $go_bin tool cover -html=$t -o $t.html

		# remove the out file
		unlink $t

		# open in respective application (e.g. web browser)
		if type open &>/dev/null; then
			open $t.html
		elif type xdg-open &>/dev/null; then
			xdg-open $t.html
		fi
	}
fi
