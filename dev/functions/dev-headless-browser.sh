function dev-headless-browser() {
    if [[ -z $1 ]]; then
        echo "Usage: dev-headless-browser <url>"
        echo "Example: dev-headless-browser http://localhost:3000"
        return
    fi

    $chromium_bin --app=$1 &
    disown;
}
