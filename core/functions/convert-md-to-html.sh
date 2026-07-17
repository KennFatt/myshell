# Convert Markdown to HTML with full support for tables, LaTeX, Mermaid diagrams
# Usage: convert-md-to-html [options] input.md [output.html]
#   If output file is omitted, uses input filename with .html extension
#   Title defaults to first heading or filename; override with -T.
#   Options:
#     -t THEME    : Mermaid theme (default, dark, forest, neutral)
#     -s          : Use custom CSS file (prompts if not specified)
#     -T TITLE    : Override page title (default: first heading or filename)
#     -n          : Do not open the generated HTML in the browser
#     -h          : Show this help message
convert-md-to-html() {
	local input_file="" output_file="" mermaid_theme="default"
	local custom_css="" use_custom_css=false page_title="" open_in_browser=true

	_convert-md-to-html--parse-args "$@" || return $?

	if [[ -z "$input_file" ]]; then
		echo "Error: No input file specified."
		echo "Usage: convert-md-to-html [options] input.md [output.html]"
		return 1
	fi

	if [[ ! -f "$input_file" ]]; then
		echo "Error: File '$input_file' not found."
		return 1
	fi

	[[ -z "$output_file" ]] && output_file="${input_file%.*}.html"

	[[ -z "$page_title" ]] && page_title="$(_convert-md-to-html--detect-title "$input_file")"

	_convert-md-to-html--ensure-gazu || return 1

	local mermaid_config="/tmp/mermaid_config_$$.json"
	printf '{ "theme": "%s" }\n' "$mermaid_theme" >"$mermaid_config"

	echo "Converting $input_file to $output_file..."
	echo "Using Mermaid theme: $mermaid_theme"

	local pandoc_exit=0
	_convert-md-to-html--run-pandoc "$input_file" "$output_file" "$mermaid_config" \
		"$page_title" "$use_custom_css" "$custom_css" || pandoc_exit=$?

	rm -f "$mermaid_config"

	if [[ $pandoc_exit -eq 0 ]]; then
		echo "Conversion successful! Output saved to: $output_file"
		if [[ "$open_in_browser" == true ]]; then
			_convert-md-to-html--open-in-browser "$output_file"
		fi
	else
		echo "Conversion failed. Please check your input file and Pandoc installation."
		return 1
	fi
}

_convert-md-to-html--parse-args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		-t | --theme) mermaid_theme="$2"; shift 2 ;;
		-s | --style)
			use_custom_css=true
			if [[ -n "$2" && "$2" != -* ]]; then
				custom_css="$2"; shift 2
			else
				shift 1
			fi
			;;
		-T | --title) page_title="$2"; shift 2 ;;
		-n | --no-open) open_in_browser=false; shift ;;
		-h | --help)
			cat <<'HELP'
Usage: convert-md-to-html [options] input.md [output.html]

Options:
  -t, --theme THEME    Mermaid theme (default, dark, forest, neutral)
  -s, --style [FILE]   Use custom CSS file (prompts if not specified)
  -T, --title TITLE    Override page title (default: first heading or filename)
  -n, --no-open        Do not open generated HTML in browser
  -h, --help           Show this help message

Examples:
  convert-md-to-html document.md
  convert-md-to-html -t dark document.md output.html
  convert-md-to-html -s custom.css document.md
  convert-md-to-html -T 'Matematika Semester 1' document.md
  convert-md-to-html -n document.md
HELP
			return 0
			;;
		-*) echo "Unknown option: $1. Use -h for help"; return 1 ;;
		*)
			if [[ -z "$input_file" ]]; then input_file="$1"
			elif [[ -z "$output_file" ]]; then output_file="$1"
			else echo "Too many arguments. Use -h for help."; return 1
			fi
			shift
			;;
		esac
	done
}

_convert-md-to-html--ensure-gazu() {
	if [ -n "$gazu_bin" ]; then return 0; fi
	echo "Warning: 'gazu' not found. Attempting install via cargo..."
	if [ -n "$cargo_bin" ]; then
		$cargo_bin install gazu
	else
		echo "Error: 'cargo' not found. Install gazu manually."
		return 1
	fi
}

_convert-md-to-html--run-pandoc() {
	local input_file="$1" output_file="$2" mermaid_config="$3"
	local page_title="$4" use_custom_css="$5" custom_css="$6"

	local asset_dir="${MY_SHELL_ROOT:-$HOME/.myshell}/assets"
	local default_css="$asset_dir/pandoc-style.css"
	local heading_permalink_header="$asset_dir/pandoc-heading-permalink.html"
	local -a cmd=($pandoc_bin "$input_file" -s --toc -o "$output_file" --filter gazu --mathjax --embed-resources)

	if [[ -f "$heading_permalink_header" ]]; then
		cmd+=(--include-in-header "$heading_permalink_header")
	fi

	if [[ -n "$page_title" ]]; then
		cmd+=(--variable "pagetitle=${page_title} | Kennan Fattahillah")
	fi

	if [[ "$use_custom_css" == false && -f "$default_css" ]]; then
		cmd+=(-c "$default_css")
	elif [[ "$use_custom_css" == true ]]; then
		if [[ -z "$custom_css" ]]; then
			echo "Please enter the path to your CSS file:"
			read -r custom_css
		fi
		if [[ -f "$custom_css" ]]; then
			cmd+=(-c "$custom_css")
			echo "Using custom CSS: $custom_css"
		else
			echo "Warning: CSS file '$custom_css' not found. Proceeding without custom CSS."
		fi
	fi

	GAZU_CONFIG="$mermaid_config" "${cmd[@]}"
}

_convert-md-to-html--detect-title() {
	local file="$1"
	local first_line
	first_line=$(head -1 "$file")
	if echo "$first_line" | grep -qE '^#{1,6}[[:space:]]'; then
		echo "$first_line" | sed 's/^#[[:space:]]*//' | sed 's/^[[:space:]]*//'
	else
		local basename="${file##*/}"
		echo "${basename%.*}"
	fi
}

_convert-md-to-html--open-in-browser() {
	local file="$1"
	local absolute_path
	absolute_path=$(cd "$(dirname "$file")" && pwd)/"$(basename "$file")"

	if command -v open &>/dev/null; then
		open "$absolute_path"
	elif command -v xdg-open &>/dev/null; then
		xdg-open "$absolute_path"
	else
		echo "Warning: Could not detect browser command (open/xdg-open)."
		echo "File saved at: $absolute_path"
		return 1
	fi
}
