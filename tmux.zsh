if [[ ! $(command -v tmux) ]] ; then
    echo "Tmux not installed.  Skipping setup."
    return 0
fi

# If we are not already in a tmux session either create it or attach to it.
if [[ ! "$TMUX" ]] ; then
   if tmux has-session -t Term ; then
       tmux attach-session -t Term
   else
       tmux new-session -t Term
   fi
fi

# Copy over configs if they don't exist.
if [[ ! -f "$HOME/.tmux.conf.local" ]] ; then
    tmux detach-session -t Term
    ln -s -f "$HOME/.dot-config/.tmux.conf" "$HOME/.tmux.conf"
    cp "$HOME/.dot-config/.tmux.conf.local" "$HOME/"
    tmux attach-session -t Term
# Update the .dot-config git repo if there are local changes.
elif [[ "$HOME/.tmux.conf.local" -nt "$HOME/.dot-config/.tmux.conf.local" ]] ; then
    cp "$HOME/.tmux.conf.local" "$HOME/.dot-config/.tmux.conf.local"
    echo "tmux .tmux.conf.local updated in .dot-config directory.  Update git repo."
fi
