path_of() {
	command -v "$1" 2>/dev/null || true
}

readonly pigz_bin="$(path_of pigz)"
readonly ncdu_bin="$(path_of ncdu)"
readonly tar_bin="$(path_of tar)"
readonly ps_bin="$(path_of ps)"
readonly wrk_bin="$(path_of wrk)"
readonly git_bin="$(path_of git)"
readonly podman_bin="$(path_of podman)"
readonly podman_compose_bin="$(path_of podman-compose)"
readonly ufw_bin="$(path_of ufw)"
readonly nvim_bin="$(path_of nvim)"
readonly vim_bin="$(path_of vim)"
readonly pngquant_bin="$(path_of pngquant)"
readonly optipng_bin="$(path_of optipng)"
readonly orbstackctl_bin="$(path_of orbctl)"
readonly vscode_bin="$(path_of code-insiders)"
readonly fzf_bin="$(path_of fzf)"

readonly jest_bin=./node_modules/jest/bin/jest.js
readonly node_bin=node

readonly chromium_bin="$(
	command -v chromium 2>/dev/null ||
	command -v chromium-browser 2>/dev/null ||
	printf '%s\n' /Applications/Chromium.app/Contents/MacOS/Chromium
)"