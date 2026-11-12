# Dev - objdump
alias obj-asm="$objdump_bin -S --disassemble \$1 > \$1_obj_asm.s"
alias src-asm="$gcc_bin -S \$1 -o _src_asm.s"

alias code-here="$vscode_bin --no-proxy-server . &; sleep 0.5; disown; exit;"
if [ -n "$pi_bolt_bin" ]; then
	alias pi='pi-bolt --offline'
	alias pi-mitm='HTTP_PROXY=http://127.0.0.1:8080 HTTPS_PROXY=http://127.0.0.1:8080 http_proxy=http://127.0.0.1:8080 https_proxy=http://127.0.0.1:8080 NODE_EXTRA_CA_CERTS=$HOME/.mitmproxy/mitmproxy-ca-cert.pem pi-bolt --offline'
else
	alias pi='pi --offline'
	alias pi-mitm='HTTP_PROXY=http://127.0.0.1:8080 HTTPS_PROXY=http://127.0.0.1:8080 http_proxy=http://127.0.0.1:8080 https_proxy=http://127.0.0.1:8080 NODE_EXTRA_CA_CERTS=$HOME/.mitmproxy/mitmproxy-ca-cert.pem pi --offline'
fi
alias fj='fj --style minimal'

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
