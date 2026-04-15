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

nanoidc() {
  local prefix="$1"
  local length=8

  if command -v nanoid >/dev/null 2>&1; then
    id=$(nanoid -s "$length")
  else
    id=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c "$length")
  fi

  if [ -n "$prefix" ]; then
    id="${prefix}-${id}"
  fi

  if command -v pbcopy >/dev/null 2>&1; then
    echo -n "$id" | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    echo -n "$id" | xclip -selection clipboard
  elif command -v wl-copy >/dev/null 2>&1; then
    echo -n "$id" | wl-copy
  fi

  echo "NanoID copied to clipboard: $id"
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

wgkey() {
  if [ -z "$1" ]; then
    echo "Usage: wgkey <client-name>"
    return 1
  fi

  local name="$1"

  wg genkey | (umask 0077 && tee "${name}.key") | wg pubkey > "${name}.pub"

  echo "Generated: ${name}.key and ${name}.pub"
}

convert-to-qr() {
  if [ -z "$1" ]; then
    echo "Usage: convert-to-qr <client-config>"
    return 1
  fi

  local file="$1"

  qrencode -t ansiutf8 -r "$file"
}

convert-mp4-to-gif() {
  local input="$1"
  local quality="${2:-60}"
  local fps scale

  if [[ -z "$input" ]]; then
    echo "Usage: convert-mp4-to-gif <input.mp4> [quality:1-100]"
    return 1
  fi

  if [[ ! -f "$input" ]]; then
    echo "Error: file not found: $input"
    return 1
  fi

  if ! [[ "$quality" =~ ^[0-9]+$ ]] || (( quality < 1 || quality > 100 )); then
    echo "Error: quality must be a number from 1 to 100"
    return 1
  fi

  fps=$(( 5 + quality / 10 ))
  scale=$(( 320 + quality * 6 ))

  local output="${input%.*}.gif"

  ffmpeg -y -i "$input" \
    -vf "fps=${fps},scale=${scale}:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
    "$output"

  echo "Created: $output"
}

pr-commits() {
  local remote="origin"
  local branch="main"
  local limit="50"
  local do_fetch=1
  local base_ref
  local merge_base

  _pr_commits_help() {
    cat <<'EOF'
Usage:
  $0
  $0 <base-branch>
  $0 <remote> <base-branch>
  $0 --branch <base-branch>
  $0 --remote <remote>
  $0 --remote <remote> --branch <base-branch>
  $0 -r <remote> -b <base-branch>
  $0 --limit <n>
  $0 -n <n>
  $0 --no-fetch
  $0 --help

Behavior:
  - Fetches the selected remote by default for correctness
  - Does not modify your current branch, index, or working tree
  - Prints commits in current HEAD that are not in <remote>/<base-branch>
  - Shows at most the latest N commits (default: 50)

Output:
  Time | Commit hash | Author | Commit title

Defaults:
  remote = origin
  branch = feat/1.0.0
  limit  = 50

Examples:
  $0
  $0 develop
  $0 upstream develop
  $0 --remote upstream --branch develop
  $0 -r upstream -b release/2.0.0
  $0 --limit 20
  $0 --no-fetch
EOF
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        _pr_commits_help
        return 0
        ;;
      -r|--remote)
        [[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
        remote="$2"
        shift 2
        ;;
      -b|--branch)
        [[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
        branch="$2"
        shift 2
        ;;
      -n|--limit)
        [[ -n "${2:-}" ]] || { echo "Missing value for $1" >&2; return 1; }
        [[ "$2" =~ ^[0-9]+$ ]] || { echo "Limit must be a non-negative integer." >&2; return 1; }
        limit="$2"
        shift 2
        ;;
      --no-fetch)
        do_fetch=0
        shift
        ;;
      *)
        if [[ -z "${pos1:-}" ]]; then
          pos1="$1"
        elif [[ -z "${pos2:-}" ]]; then
          pos2="$1"
        else
          echo "Too many arguments." >&2
          _pr_commits_help >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [[ -n "${pos1:-}" && -n "${pos2:-}" ]]; then
    remote="$pos1"
    branch="$pos2"
  elif [[ -n "${pos1:-}" ]]; then
    branch="$pos1"
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a Git repository." >&2
    return 1
  fi

  if [[ "$do_fetch" -eq 1 ]]; then
    git fetch --prune "$remote" || return 1
  fi

  base_ref="${remote}/${branch}"

  if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
    echo "Base ref not found: $base_ref" >&2
    return 1
  fi

  merge_base="$(git merge-base "$base_ref" HEAD)" || return 1

  git log \
    --date=format:'%Y-%m-%d %H:%M:%S' \
    --pretty=format:'%ad | %H | %an | %s' \
    --max-count="$limit" \
    HEAD --not "$base_ref"
}