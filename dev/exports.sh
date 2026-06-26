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

## Bun
if [[ -d $HOME/.bun ]]; then
	export BUN_INSTALL="$HOME/.bun"
	export PATH=$BUN_INSTALL/bin:$PATH
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

# OrbStack as a docker (MacOS)
if [[ -x $orbstackctl_bin ]]; then
	export DOCKER_HOST="unix://$HOME/.orbstack/run/docker.sock"
fi

## Python
if [[ -d $HOME/.local/bin ]]; then
	export PYTHON_LOCAL=$HOME/.local
	export PATH=$PATH:$PYTHON_LOCAL/bin
fi

## Node Version Manager (NVM)
if [[ -d $HOME/.nvm ]]; then
	export NVM_DIR="$HOME/.nvm"

	_myshell_nvm_resolve_alias() {
		local alias_name="$1"
		local alias_file alias_value

		while [[ -n "$alias_name" && -f "$NVM_DIR/alias/$alias_name" ]]; do
			alias_file="$NVM_DIR/alias/$alias_name"
			IFS= read -r alias_value < "$alias_file"
			[[ "$alias_value" = "$alias_name" ]] && break
			alias_name="$alias_value"
		done

		printf '%s\n' "$alias_name"
	}

	_myshell_nvm_default_version="$(_myshell_nvm_resolve_alias default)"
	if [[ -n "$_myshell_nvm_default_version" && -d "$NVM_DIR/versions/node/$_myshell_nvm_default_version/bin" ]]; then
		export PATH="$NVM_DIR/versions/node/$_myshell_nvm_default_version/bin:$PATH"
	fi
	unset _myshell_nvm_default_version
	unset -f _myshell_nvm_resolve_alias 2>/dev/null || unset _myshell_nvm_resolve_alias

	nvm() {
		unset -f nvm 2>/dev/null || unset nvm
		[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
		nvm "$@"
	}
fi

## Go Version Manager (GVM)
if [[ -d $HOME/.gvm ]]; then
	export GVM_ROOT="$HOME/.gvm"
	[[ -s "$GVM_ROOT/environments/default" ]] && source "$GVM_ROOT/environments/default"

	gvm() {
		unset -f gvm 2>/dev/null || unset gvm
		[[ -s "$GVM_ROOT/scripts/gvm" ]] && source "$GVM_ROOT/scripts/gvm"
		gvm "$@"
	}
fi

## SDKMan (Java SDK manager)
if [[ -d $HOME/.sdkman ]]; then
	export SDKMAN_DIR="$HOME/.sdkman"

	sdk() {
		unset -f sdk 2>/dev/null || unset sdk
		[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
		sdk "$@"
	}
fi

## PNPM (Another node package manager)
if [[ -d $HOME/.local/share/pnpm ]]; then
	export PNPM_HOME="$HOME/.local/share/pnpm"
	export PATH=$PNPM_HOME:$PATH
fi

if [ "$(uname)" = "Darwin" ]; then
	# Libpq keg-only
	export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

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

## React Editor
if [[ -x $vscode_bin ]]; then
	export REACT_EDITOR=$vscode_bin
fi

if [[ -d $HOME/.pi ]]; then
	export PI_HARNESS_MODEL_PATTERN=deepseek,mimo
	export PI_HARNESS_CACHE_STRIP_REASONING=false
	export PI_HARNESS_HASHLINES_ENABLED=false
fi