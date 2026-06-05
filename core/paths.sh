path_of() {
	command -v "$1" 2>/dev/null || true
}

pigz_bin="$(path_of pigz)"
ncdu_bin="$(path_of ncdu)"
tar_bin="$(path_of tar)"
ps_bin="$(path_of ps)"
wrk_bin="$(path_of wrk)"
git_bin="$(path_of git)"
podman_bin="$(path_of podman)"
podman_compose_bin="$(path_of podman-compose)"
ufw_bin="$(path_of ufw)"
nvim_bin="$(path_of nvim)"
vim_bin="$(path_of vim)"
pngquant_bin="$(path_of pngquant)"
optipng_bin="$(path_of optipng)"
orbstackctl_bin="$(path_of orbctl)"
vscode_bin="$(path_of code-insiders)"
fzf_bin="$(path_of fzf)"

jest_bin=./node_modules/jest/bin/jest.js
node_bin=node

chromium_bin="$(
	command -v chromium 2>/dev/null ||
	command -v chromium-browser 2>/dev/null ||
	printf '%s\n' /Applications/Chromium.app/Contents/MacOS/Chromium
)"