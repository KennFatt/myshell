# Cargo (Rust toolchain)
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# Python user installs (pipx, pip --user)
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# myshell scripts — add to PATH so they're callable by name
MYSHELL_SCRIPTS_DIR="$HOME/.myshell/scripts"
if [ -d "$MYSHELL_SCRIPTS_DIR" ]; then
	export PATH="$MYSHELL_SCRIPTS_DIR:$PATH"
fi