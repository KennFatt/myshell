## Node
## Set node max heap: @see https://stackoverflow.com/a/59572966
export NODE_OPTIONS="--max-old-space-size=4096"

## NextJS
## @see https://nextjs.org/telemetry
export NEXT_TELEMETRY_DISABLED=1

## Deno
if [[ -d $HOME/.deno ]]; then
	export DENO_INSTALL=$HOME/.deno
	export PATH=$PATH:$DENO_INSTALL/bin
fi

## Rust (cargo)
if [[ -d $HOME/.cargo ]]; then
	export RUST_BIN=$HOME/.cargo/bin
	# Init the Rust' environment.
	. $HOME/.cargo/env
fi

## Golang
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

## PHP Composer global
if [[ -d $HOME/.config/composer ]]; then
	export PATH=$PATH:$HOME/.config/composer/vendor/bin
fi

## Python
if [[ -d $HOME/.local/bin ]]; then
	export PYTHON_LOCAL=$HOME/.local
	export PATH=$PATH:$PYTHON_LOCAL/bin
fi

if [[ -d $HOME/.colima ]]; then
	export DOCKER_HOST="unix://$HOME/.colima/docker.sock"
fi

if [ "$(uname)" = "Darwin" ]; then
	# Libpq keg-only
	export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
fi
