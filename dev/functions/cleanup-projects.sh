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
