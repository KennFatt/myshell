mytemplate() {
	local templates_dir="$MYSPACE_HOME/templates"

	if [ ! -d "$templates_dir" ]; then
		echo "Error: templates directory not found: $templates_dir" >&2
		return 1
	fi

	local usage="Usage:
  mytemplate --list
  mytemplate <template_name>
  mytemplate <template_name> <new_name>"

	if [ $# -eq 0 ]; then
		echo "$usage" >&2
		return 1
	fi

	if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
		echo "Available templates in: $templates_dir"
		ls -1h "$templates_dir"
		return 0
	fi

	local src_name="$1"
	local dst_name="${2:-$1}"
	local src_path="$templates_dir/$src_name"
	local dst_path="./$dst_name"

	if [ ! -e "$src_path" ]; then
		echo "Error: template not found: $src_name" >&2
		return 1
	fi

	if [ -e "$dst_path" ]; then
		echo "Error: destination already exists: $dst_name" >&2
		return 1
	fi

	cp -R "$src_path" "$dst_path"

	if [ $? -ne 0 ]; then
		echo "Error: failed to copy template." >&2
		return 1
	fi

	echo "Copied '$src_name' -> '$dst_name'"
}
