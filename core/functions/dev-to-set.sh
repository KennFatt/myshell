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
