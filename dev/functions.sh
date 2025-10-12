if [[ -f ~/.clang-format/.clang-format ]]; then
	function init-clang-format() {
		cp ~/.clang-format/.clang-format .
	}
fi

if [[ -d ~/.prettier ]]; then
	function init-prettier() {
		cp -a ~/.prettier/. .
	}
fi

if [[ -d ~/.htmlhint ]]; then
	function init-htmlhint() {
		cp ~/.htmlhint/.htmlhintrc .
	}
fi

function wrk-base() {
	if [[ -z $1 || -z $2 ]]; then
		echo "Usage: wrk-base <conn: int> <url: string>"
		echo "Example: wrk-base 100 http://localhost:3030/v1/healthz"
		return
	fi

	$wrk_bin -t4 -d10s -c$1 --latency $2
}

function dev-headless-browser() {
    if [[ -z $1 ]]; then
        echo "Usage: dev-headless-browser <url>"
        echo "Example: dev-headless-browser http://localhost:3000"
        return
    fi

    $chromium_bin --app=$1 &
    disown;
}

# PNG Optimizer (lossy)
if [ -x $pngquant_bin ]; then
    function png-compress-lossy() {
        if [[ -z $1 ]]; then
            echo "Usage: png-comperss-lossy <file>"
            echo "Example: png-compress-lossy apple.png"
            echo "Example: png-compress-lossy *.png"
            return
        fi

        $pngquant_bin --speed 1 $1
    }
fi

if [ -x $optipng_bin ]; then
    function png-compress-lossless() {
        if [[ -z $1 ]]; then
            echo "Usage: png-comperss-lossless <file>"
            echo "Example: png-compress-lossless apple.png"
            echo "Example: png-compress-lossless *.png"
            return
        fi

        echo "Start compressing the file..."
        $optipng_bin -strip all -o7 -silent -force $1
        echo "Comperssiong succeed!"
    }
fi

if [[ -f $jest_bin ]]; then
    # node node_modules/jest/bin/jest.js Counter.test.tsx --coverage --reporters=jest-junit --watchAll=false --coverageDirectory=reportcoverage -c ./jest.config.ts -t 'Counter'
    function dev-jest-coverage() {
        if [[ -z $1 ]]; then
            echo "Usage: $0 <file_name: string|regex> <test_name: string|regex>"
            echo "Example: $0 Counter.test.tsx 'Counter component'"
            return
        fi

        local reportcoverage_dir='reportcoverage'

        # test cleanup
        rm -rf junit.xml $reportcoverage_dir

        # run the jest
        $node_bin $jest_bin $1 \
            --runInBand \
            --coverage \
            --reporters=default \
            --verbose \
            --reporters=jest-junit \
            --coverageReporters=html \
            --coverageDirectory=$reportcoverage_dir \
            --collectCoverageFrom=''

        local jest_coverage_report=$reportcoverage_dir/index.html

        # open the output in browser
        local report_file_path=$(pwd)/$jest_coverage_report
        echo "Opening file: $report_file_path in the brower..."
        $chromium_bin --app=file://$report_file_path >/dev/null 2>&1 &
        disown
    }
fi

function cleanup-projects() {
  local cwd
  cwd="$(pwd)"

  # Loop through directories only (1 level)
  for dir in "$cwd"/*/; do
    [ -d "$dir" ] || continue

    # Required folders
    local next_dir="$dir/.next"
    local node_modules_dir="$dir/node_modules"
    local coverage_dir="$dir/coverage"
    local report_coverage_dir="$dir/reportcoverage"

    # Check if all exist
    if [ -d "$next_dir" ] || [ -d "$node_modules_dir" ] || [ -d "$coverage_dir" ] || [ -d "$report_coverage_dir" ]; then
      rm -rf "$next_dir" "$node_modules_dir" "$coverage_dir" "$report_coverage_dir"
      echo "✅ Cleaned: $(basename "$dir")"
    else
      echo "⏩ Skipped: $(basename "$dir")"
    fi
  done
}

function dev-to-set() {
  if [ -z "$1" ]; then
    echo "Usage: $0 [--format csv|nl|sql] 'item1, item2, item3,...'"
    return 1
  fi

  # default format
  format="csv"

  # check if first arg is --format
  if [ "$1" = "--format" ]; then
    format="$2"
    shift 2
  fi

  if [ -z "$1" ]; then
    echo "Usage: $0 [--format csv|nl|sql] 'item1, item2, item3,...'"
    return 1
  fi

  # normalize, dedupe (preserve order)
  items=$(echo "$1" \
    | tr ',' '\n' \
    | sed 's/^ *//;s/ *$//' \
    | awk '!seen[$0]++')

  case "$format" in
    csv)
      echo "$items" | paste -sd, -
      ;;
    nl)
      echo "$items" | sed 's/$/,/'
      ;;
    sql)
      echo "$items" | sed 's/.*/"&",/'
      ;;
    *)
      echo "Unknown format: $format"
      return 1
      ;;
  esac
}

uuidc() {
  uuid="$(uuidgen)"

  if [ "$(uname)" = "Darwin" ]; then
    # macOS
    printf "%s" "$uuid" | pbcopy
  elif [ "$(uname)" = "Linux" ]; then
    # Linux (requires xclip or xsel)
    if command -v xclip >/dev/null 2>&1; then
      printf "%s" "$uuid" | xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
      printf "%s" "$uuid" | xsel --clipboard --input
    else
      echo "Error: no clipboard tool (xclip/xsel) found." >&2
      return 1
    fi
  else
    echo "Unsupported OS: $(uname)" >&2
    return 1
  fi

  echo "UUID copied to clipboard: $uuid"
}

if [ "$(uname)" = "Linux" ]; then
	function go-gen-cover() {
		# Check dependencies
		if ! type xargs &>/dev/null; then
			echo "error: 'xargs' command is missing"
			return 1
		fi

		if ! type go &>/dev/null; then
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
		go list ./... | grep $module_name | xargs go test -coverprofile=$t && go tool cover -html=$t -o $t.html

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