if [ -n "${optipng_bin:-}" ] && [ -x "$optipng_bin" ]; then
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
