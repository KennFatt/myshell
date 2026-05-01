if [ -n "${pngquant_bin:-}" ] && [ -x "$pngquant_bin" ]; then
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
