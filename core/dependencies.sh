# MyShell Dependencies Manifest
# Single source of truth for all external tools used across the project.
# Each tool is discovered via command -v and stored in a ${name}_bin variable.
# The myshell-doctor function iterates these to verify the environment.
#
# Naming convention: <tool_name>_bin
#   tool_name uses underscores for special chars: podman_compose_bin, fail2ban_client_bin

path_of() {
	command -v "$1" 2>/dev/null || true
}

# CORE - essential system tools
pigz_bin="$(path_of pigz)"
ncdu_bin="$(path_of ncdu)"
tar_bin="$(path_of tar)"
ps_bin="$(path_of ps)"
install_bin="$(path_of install)"
openssl_bin="$(path_of openssl)"
ssh_bin="$(path_of ssh)"
rsync_bin="$(path_of rsync)"
curl_bin="$(path_of curl)"
jq_bin="$(path_of jq)"
watch_bin="$(path_of watch)"
lsof_bin="$(path_of lsof)"
less_bin="$(path_of less)"
sha256sum_bin="$(path_of sha256sum)"

# SHELL - shell enhancements and TUI
lsd_bin="$(path_of lsd)"
fzf_bin="$(path_of fzf)"
fastfetch_bin="$(path_of fastfetch)"
inxi_bin="$(path_of inxi)"
rga_bin="$(path_of rga)"

# NETWORK - network inspection and security
ufw_bin="$(path_of ufw)"
iftop_bin="$(path_of iftop)"
ss_bin="$(path_of ss)"
dig_bin="$(path_of dig)"
nslookup_bin="$(path_of nslookup)"
fail2ban_client_bin="$(path_of fail2ban-client)"
wg_bin="$(path_of wg)"
systemctl_bin="$(path_of systemctl)"
journalctl_bin="$(path_of journalctl)"

# DEV - programming languages and development tools
git_bin="$(path_of git)"
node_bin="$(path_of node)"
go_bin="$(path_of go)"
python3_bin="$(path_of python3)"
cargo_bin="$(path_of cargo)"
pandoc_bin="$(path_of pandoc)"
gazu_bin="$(path_of gazu)"
wrk_bin="$(path_of wrk)"
objdump_bin="$(path_of objdump)"
gcc_bin="$(path_of gcc)"
nanoid_bin="$(path_of nanoid)"
uuidgen_bin="$(path_of uuidgen)"

# EDITORS and IDEs
nvim_bin="$(path_of nvim)"
vim_bin="$(path_of vim)"
vscode_bin="$(path_of code-insiders)"

# CONTAINER - container engines
docker_bin="$(path_of docker)"
podman_bin="$(path_of podman)"
podman_compose_bin="$(path_of podman-compose)"
orbstackctl_bin="$(path_of orbctl)"

# MEDIA - image and video processing
pngquant_bin="$(path_of pngquant)"
optipng_bin="$(path_of optipng)"
ffmpeg_bin="$(path_of ffmpeg)"
qrencode_bin="$(path_of qrencode)"

# CLIPBOARD - platform-specific clipboard tools
pbcopy_bin="$(path_of pbcopy)"
xclip_bin="$(path_of xclip)"
xsel_bin="$(path_of xsel)"
wl_copy_bin="$(path_of wl-copy)"

# PACKAGE MANAGERS
apt_get_bin="$(path_of apt-get)"
brew_bin="$(path_of brew)"
dnf_bin="$(path_of dnf)"
pacman_bin="$(path_of pacman)"
yay_bin="$(path_of yay)"

# WEB - web scraping and content extraction
shot_scraper_bin="$(path_of shot-scraper)"
trafilatura_bin="$(path_of trafilatura)"
glow_bin="$(path_of glow)"

# CHROMIUM - special discovery with multi-binary fallback
chromium_bin="$(
	command -v chromium 2>/dev/null ||
	command -v chromium-browser 2>/dev/null ||
	printf '%s\n' /Applications/Chromium.app/Contents/MacOS/Chromium
)"

# PROJECT-LOCAL - relative paths, not system-wide discoverable
jest_bin="./node_modules/jest/bin/jest.js"

# Category groupings used by myshell-doctor.
# Maps tool variable names to display categories.
MDS_CATEGORIES=(
	"CORE:pigz_bin:ncdu_bin:tar_bin:ps_bin:install_bin:openssl_bin:ssh_bin:rsync_bin:curl_bin:jq_bin:watch_bin:lsof_bin:less_bin:sha256sum_bin"
	"SHELL:lsd_bin:fzf_bin:fastfetch_bin:inxi_bin:rga_bin"
	"NETWORK:ufw_bin:iftop_bin:ss_bin:dig_bin:nslookup_bin:fail2ban_client_bin:wg_bin:systemctl_bin:journalctl_bin"
	"DEV:git_bin:node_bin:go_bin:python3_bin:cargo_bin:pandoc_bin:gazu_bin:wrk_bin:objdump_bin:gcc_bin:nanoid_bin:uuidgen_bin"
	"EDITORS:nvim_bin:vim_bin:vscode_bin"
	"CONTAINER:docker_bin:podman_bin:podman_compose_bin:orbstackctl_bin"
	"MEDIA:pngquant_bin:optipng_bin:ffmpeg_bin:qrencode_bin"
	"CLIPBOARD:pbcopy_bin:xclip_bin:xsel_bin:wl_copy_bin"
	"PACKAGE_MANAGERS:apt_get_bin:brew_bin:dnf_bin:pacman_bin:yay_bin"
	"WEB:shot_scraper_bin:trafilatura_bin:glow_bin"
	"SPECIAL:chromium_bin:jest_bin"
)
