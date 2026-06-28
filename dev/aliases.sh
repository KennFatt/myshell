# Dev - objdump
alias obj-asm="$objdump_bin -S --disassemble \$1 > \$1_obj_asm.s"
alias src-asm="$gcc_bin -S \$1 -o _src_asm.s"

alias code-here="$vscode_bin --no-proxy-server . &; sleep 0.5; disown; exit;"

# Podman as docker
if [[ -f $podman_bin ]]; then
	alias docker="$podman_bin"
fi
if [[ -f $podman_compose_bin ]]; then
	alias docker-compose="$podman_compose_bin"
fi

# Android emulator
if [[ -d $ANDROID_HOME ]]; then
	alias android-device-list='emulator -list-avds'
	alias android-device-run='emulator -avd $1'
fi

if [ "$(uname)" = "Darwin" ]; then
	alias clipboard-to-json='pbpaste | json-to-block-comment'
fi
