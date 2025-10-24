if [ "$(uname)" = "Linux" ]; then
	readonly pigz_bin=/usr/bin/pigz
	readonly ncdu_bin=/usr/bin/ncdu
	readonly tar_bin=/usr/bin/tar
	readonly ps_bin=/usr/bin/ps
	readonly wrk_bin=/usr/bin/wrk
	readonly git_bin=/usr/bin/git
	readonly podman_bin=/usr/bin/podman
	readonly podman_compose_bin=/usr/bin/podman-compose
elif [ "$(uname)" = "Darwin" ]; then
	readonly pigz_bin=/opt/homebrew/bin/pigz
	readonly ncdu_bin=/opt/homebrew/bin/ncdu
	readonly chromium_bin=/Applications/Chromium.app/Contents/MacOS/Chromium
	readonly pngquant_bin=/opt/homebrew/bin/pngquant
	readonly optipng_bin=/opt/homebrew/bin/optipng
	readonly tar_bin=/usr/bin/tar
	readonly ps_bin=/usr/bin/ps
	readonly wrk_bin=/opt/homebrew/bin/wrk
	readonly git_bin=/usr/bin/git
fi

readonly jest_bin=./node_modules/jest/bin/jest.js
readonly node_bin=node
