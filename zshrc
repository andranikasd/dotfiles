########################################################################
# .zshrc – Basic Zsh Configuration File                                #
# Author: YOU (edited by ChatGPT)                                      #
# Description: Minimal, clean Zsh config with enhanced GNU-style docs  #
# Intended for: Linux dev environments, WSL, terminals, or servers     #
########################################################################

########################################
# SHELL BEHAVIOR                       #
########################################

# If you typo a command (e.g. "sl" instead of "ls"), try to correct it
setopt CORRECT

# Kill the bell. Nobody likes a terminal beep.
setopt NO_BEEP

# Allow '#' in commands like: echo foo # comment
setopt INTERACTIVE_COMMENTS

# History should be shared across all terminals, not isolated per shell
setopt SHARE_HISTORY

# Don’t overwrite history when shell exits, just add new lines to the file
setopt APPEND_HISTORY

# Don’t store duplicate commands in history
setopt HIST_IGNORE_ALL_DUPS

# If you type a directory name, just cd into it without typing 'cd'
setopt AUTO_CD

# Enable Zsh’s autocompletion system
autoload -Uz compinit
compinit

########################################
# HISTORY CONFIG                       #
########################################

# Where to save history
export HISTFILE="$HOME/.data/HISTORY"

# How many commands to keep in memory
export HISTSIZE=5000

# How many to keep in file
export SAVEHIST=10000

########################################
# PATHS & ENV VARS                     #
########################################

# Add personal bin dirs to PATH (modify as needed)
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Default editor — change to vim/nano if you're not a neovim user
export EDITOR="vim"

# Pager (used for man, git diff, etc)
export PAGER="less"

########################################
# PROMPT SETUP                         #
########################################
# Function to get current Git branch and short SHA (6 chars)
# Outputs: [branch-name @ abc123]
git_prompt_info() {
  # Only run if we're inside a Git repository
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    local branch sha
    # Get current branch name (or HEAD in detached state)
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || echo "(no branch)")
    # Get current commit SHA (shorten to 6 chars)
    sha=$(git rev-parse --short=6 HEAD 2>/dev/null)
    echo "%F{red}${branch}%F{white} -> %F{cyan}${sha}%F{white}"
  fi
}

# Simple colored prompt:
# user@host:~/path $
setopt PROMPT_SUBST  # <- enable command substitution in prompt

PROMPT='%F{white}%n@%F{yellow}%m%f:%~%f $(git_prompt_info) %# '
# %m = hostname (short)
# %~ = current dir (abbreviated)
# %# = shows "#" if root, "$" otherwise
# %F{color} ... %f = set/reset color

########################################
# ALIASES                              #
########################################

# Make common file commands safer (ask before overwrite)
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# Directory listing shortcuts
alias ll='ls -alF'     # Long list, show all, classify
alias la='ls -A'       # Show all except . and ..
alias l='ls -CF'       # Columns, classify, fast

# Reload config without restarting shell
alias reload='source ~/.zshrc'

########################################
# FNM: Node.js version manager (if used)
########################################

# Only enable if fnm is installed
if command -v fnm > /dev/null 2>&1; then
  eval "$(fnm env)"
fi

########################################
# GOLANG PATH SETUP (manual install)   #
########################################

# If you installed Go to $HOME/go, make sure binaries are usable
if [ -d "$HOME/go/bin" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi

########################################
# OPTIONAL: Plugins (if you clone them manually)
########################################

# Autosuggestions (gray ghost text while typing)
if [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

########################################
# PROMPT INIT (only if you want to style it later)
########################################

# promptinit
# prompt default  # or use: prompt pure (if installed)

#######################################################################
# END OF FILE                                                         #
# Keep it clean. Build from here.                                     #
#######################################################################


autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform
#######################################################################
# Some exports
#######################################################################
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.config/emacs/bin
export PATH=$PATH:/opt/nvim-linux-x86_64/bin
export PATH=$PATH:/home/andranik/.local/share/nvim/mason/
#######################################################################
# Some aliases
#######################################################################
alias tf='terraform'
alias vi='nvim'
