#
# This file isn't copied over to the home directory instead add a .zshenv
# file to the home directory and add the following to that file:
#
#        export ZDOTDIR="$HOME/.dot-config"
#

################################################################################
#
#                                 PROMPT
#
################################################################################

autoload -Uz promptinit
promptinit

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

################################################################################
#
#                                 HISTORY
#
################################################################################

setopt histignorealldups sharehistory

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

################################################################################
#
#                                 COMPLETION
#
################################################################################

autoload -Uz compinit
compinit

# zstyle ':completion:*' auto-description 'specify: %d'
# zstyle ':completion:*' completer _expand _complete _correct _approximate
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' menu select=2
# eval "$(dircolors -b)"
# zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# zstyle ':completion:*' menu select=long
# zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
# zstyle ':completion:*' use-compctl false
# zstyle ':completion:*' verbose true

# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
# zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

################################################################################
#
#                           EVNIRONMENT VARIABLES
#
################################################################################

export PATH="/usr/local/go/bin:$GOPATH/bin:$HOME/.cargo/bin:$HOME/.local/lib/python3.6/site-packages:$PATH"
export GOPATH="$HOME/Code/go"
export AGKOZAK_PROMPT_DIRTRIM=6

################################################################################
#
#                                 ALIASES
#
################################################################################

alias ll='ls -alF --color'
alias ef='emacsclient -t'

################################################################################
#
#                                 PLUGINS
#
################################################################################

# Oh-my-zsh thing.  Not used but kept as a reference due to a recommendation
# from Vasu Argawal.
plugins=(
    # gitfast             ## Take a look, maybe useful for large repos.
)

source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

################################################################################
#
#                              SUB-CONFIGS
#
################################################################################

source $HOME/.dot-config/most.zsh
source $HOME/.dot-config/tmux.zsh
source $HOME/.dot-config/emacs.zsh
source $HOME/.dot-config/agkozak-zsh-prompt.plugin.zsh
