## Node
## Set node max heap: @see https://stackoverflow.com/a/59572966
export NODE_OPTIONS="--max-old-space-size=4096"

## NextJS
## @see https://nextjs.org/telemetry
export NEXT_TELEMETRY_DISABLED=1
export NEXT_TURBOPACK_EXPERIMENTAL_USE_SYSTEM_TLS_CERTS=0

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

# Podman as a docker
if [[ -f $podman_bin ]]; then
	export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
fi

## Python
if [[ -d $HOME/.local/bin ]]; then
	export PYTHON_LOCAL=$HOME/.local
	export PATH=$PATH:$PYTHON_LOCAL/bin
fi

## Node Version Manager (NVM)
if [[ -d $HOME/.nvm ]]; then
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

## Go Version Manager (GVM)
if [[ -d $HOME/.gvm ]]; then
	[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
fi

## SDKMan (Java SDK manager)
if [[ -d $HOME/.sdkman ]]; then
	export SDKMAN_DIR="$HOME/.sdkman"
	[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

## PNPM (Another node package manager)
if [[ -d $HOME/.local/share/pnpm ]]; then
	export PNPM_HOME="$HOME/.local/share/pnpm"
	export PATH=$PNPM_HOME:$PATH
fi

if [ "$(uname)" = "Darwin" ]; then
	# Libpq keg-only
	export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

	## Colima
	if [[ -d $HOME/.colima ]]; then
		export DOCKER_HOST="unix://$HOME/.colima/docker.sock"
	fi

	## Android SDK
	if [[ -d $HOME/Library/Android/sdk ]]; then
		export ANDROID_HOME=$HOME/Library/Android/sdk
		export PATH=$PATH:$ANDROID_HOME/emulator
		export PATH=$PATH:$ANDROID_HOME/tools
		export PATH=$PATH:$ANDROID_HOME/tools/bin
		export PATH=$PATH:$ANDROID_HOME/platform-tools
		export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
	fi
fi
