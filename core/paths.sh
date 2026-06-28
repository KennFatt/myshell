# myshell scripts — add to PATH so they're callable by name
MYSHELL_SCRIPTS_DIR="$HOME/.myshell/scripts"
if [ -d "$MYSHELL_SCRIPTS_DIR" ]; then
	export PATH="$MYSHELL_SCRIPTS_DIR:$PATH"
fi