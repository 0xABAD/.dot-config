if [[ ! $(command -v emacs) ]] ; then
    echo "Emacs not installed.  Skipping setup."
    return 0
fi

# Check if emacs server daemon is not running.  We want to use the daemon to
# make speedy Emacs edits within the terminal.
if [[ $(ps -ef | grep "emacs --daemon" | grep -v "grep" | wc -l) -eq 0 ]] ; then
    emacs --daemon
fi

# Check if the emacs config directory exist and if not then download comma-mode
# and copy over the init.el file.
if [[ ! -d "$HOME/.emacs.d" ]] ; then
    mkdir -p "$HOME/.emacs.d"
    cp "$HOME/.dot-config/init.el" "$HOME/.emacs.d/"
    git clone "https://github.com/0xABAD/comma-mode" "$HOME/.emacs.d/lisp"
# Check if init.el is newer than the saved one in .dot-config in order to update the git repo.
elif [[ "$HOME/.emacs.d/init.el" -nt "$HOME/.dot-config/init.el" ]] ; then
    cp "$HOME/.emacs.d/init.el" "$HOME/.dot-config/"
    echo "Emacs init.el updated in .dot-config directory.  Update git repo."
fi
