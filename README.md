## MyShell

MyShell is an organized and (personal) opionated collection of shell script for all my machine.

### How to use

1. Update your rc file and add this line:

```sh
[[ -f $HOME/.myshell/_init.sh ]] && . $HOME/.myshell/_init.sh
```

2. Restart your shell session and done!

### Diagnostics

Run `myshell-doctor` to verify all expected tools are installed:

```sh
myshell-doctor
```

It checks 60+ tools across categories (core, dev, network, media, etc.). All are optional -- install what you need, ignore the rest.