myshell-doctor() {
	if [ ${#MDS_CATEGORIES[@]} -eq 0 ]; then
		echo "Error: MDS_CATEGORIES not found. Is dependencies.sh loaded?"
		return 1
	fi

	echo "== MyShell Doctor =="
	echo ""

	local tool_count=0 tools_found=0 tools_missing=0 tools_warn=0

	for entry in "${MDS_CATEGORIES[@]}"; do
		local category="${entry%%:*}"
		local tools="${entry#*:}"

		echo "--- $category ---"

		local remaining="$tools"
		while [ -n "$remaining" ]; do
			local tool_var="${remaining%%:*}"
			remaining="${remaining#*:}"
			[ "$tool_var" = "$remaining" ] && remaining=""

			[ -n "$tool_var" ] || continue
			tool_count=$((tool_count + 1))

			# indirect variable dereference
			tool_path=""
			eval "tool_path=\"\$$tool_var\""

			if [ -n "$tool_path" ]; then
				if [ -x "$tool_path" ] 2>/dev/null; then
					printf "  [OK]  %-24s %s\n" "${tool_var%_bin}" "$tool_path"
					tools_found=$((tools_found + 1))
				else
					printf "  [?]   %-24s %s\n" "${tool_var%_bin}" "$tool_path"
					tools_warn=$((tools_warn + 1))
				fi
			else
				printf "  [--]  %-24s not found\n" "${tool_var%_bin}"
				tools_missing=$((tools_missing + 1))
			fi
		done

		echo ""
	done

	echo "== Summary =="
	echo "  Found:   $tools_found"
	[ "$tools_warn" -gt 0 ] && echo "  Warn:    $tools_warn (path set but not executable)"
	echo "  Missing: $tools_missing"
	echo "  Total:   $tool_count"

	return "$tools_missing"
}
