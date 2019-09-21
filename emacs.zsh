if [[ ! $(command -v emacs) ]] ; then
    echo "Emacs not installed.  Skipping setup."
    return 0
fi

# Check if emacs server daemon is not running.  We want to use the daemon to
# make speedy Emacs edits within the terminal.
if [[ $(ps -ef | grep "emacs --daemon" | grep -v "grep" | wc -l) -eq 0 ]] ; then
    emacs --daemon
fi
