########################################################################
# .zshrc – Basic Zsh Configuration File                                #
# Author: Andranik Grigoryan                                           #
# Description: Minimal, clean Zsh config with enhanced GNU-style docs  #
# Intended for: Linux dev environments, WSL, terminals, or servers     #
########################################################################

########################################
# SHELL BEHAVIOR                       #
########################################

# Enable Emacs-style keybindings (so arrow keys work as expected)
bindkey -e

# Fix common arrow-key misbindings:
# ─ Left/Right move the cursor
bindkey '\e[D' backward-char
bindkey '\e[C' forward-char
# ─ Up/Down navigate history
bindkey '\e[A' up-line-or-history
bindkey '\e[B' down-line-or-history

# If you typo a command (e.g. "sl" instead of "ls"), zsh will prompt a correction
setopt CORRECT

# Disable the terminal bell
setopt NO_BEEP

# Allow inline comments after a command using “#”
setopt INTERACTIVE_COMMENTS

# Auto-`cd` when you type a directory name
setopt AUTO_CD

# Load and initialize the completion system
autoload -Uz compinit
compinit

########################################
# ENHANCED HISTORY HANDLING            #
########################################

# File where your command history is saved
export HISTFILE="$HOME/.data/HISTORY"

# Number of commands to keep in memory (increase as desired)
export HISTSIZE=20000

# Number of commands to save to disk
export SAVEHIST=50000

# Don’t store duplicate entries; expire older duplicates first
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST

# Ignore commands that start with a space
setopt HIST_IGNORE_SPACE

# Immediately append each command to the history file, with timestamp
setopt INC_APPEND_HISTORY
setopt INC_APPEND_HISTORY_TIME

# Share history across all sessions
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Enable incremental history search with Ctrl-R / Ctrl-S
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

########################################
# PATHS & ENV VARS                     #
########################################

# Include your personal bin directories first
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Default editor (change to nvim if preferred)
export EDITOR="vim"

# Pager for long output (man pages, git diffs, etc.)
export PAGER="less"

########################################
# PROMPT SETUP                         #
########################################

# Allow command-substitution in the prompt (for git info)
setopt PROMPT_SUBST

# Function: show current Git branch and short SHA, if in a repo
git_prompt_info() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local branch sha
    branch=$(git symbolic-ref --short HEAD 2>/dev/null \
             || git describe --tags --exact-match 2>/dev/null \
             || echo "(no branch)")
    sha=$(git rev-parse --short=6 HEAD 2>/dev/null)
    echo "%F{red}${branch}%F{white} → %F{cyan}${sha}%F{white}"
  fi
}

# Function: SSH into a GCE VM with an optional --project override
gcp-vm() {
  local project="rare-palace-269609"

  # Parse flags
  while [[ $# -gt 0 && "$1" =~ ^- ]]; do
    case "$1" in
      --project|-p)
        shift
        project="$1"
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 1
        ;;
    esac
    shift
  done

  # Validate arguments
  if [[ $# -ne 2 ]]; then
    cat <<EOF >&2
Usage: gcp-vm [--project PROJECT] ZONE INSTANCE
  ZONE      the GCE zone (e.g. us-central1-a)
  INSTANCE  the VM name
Options:
  -p, --project   override default project (rare-palace-269609)
EOF
    return 1
  fi

  local zone="$1" instance="$2"

  gcloud compute ssh \
    --project="$project" \
    --zone="$zone" \
    "$instance"
}

# Define the visual prompt
PROMPT='%F{white}%n@%F{yellow}%m%f:%~%f $(git_prompt_info) %# '
# ─ %n = username
# ─ %m = hostname
# ─ %~ = current directory (abbreviated)
# ─ %# = “#” for root, “$” for normal users

########################################
# ALIASES                              #
########################################

# Interactive file operations
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# Directory listings
alias ll='ls -alF'     # detailed list, classify
alias la='ls -A'       # show hidden except . and ..
alias l='ls -CF'       # columns, classify, fast

# Reload this config
alias reload='source ~/.zshrc'

########################################
# VERSION MANAGERS & LANGUAGES         #
########################################

# fnm (Fast Node Manager), if installed
if command -v fnm &>/dev/null; then
  eval "$(fnm env)"
fi

# Go binaries (if Go installed under $HOME/go)
if [ -d "$HOME/go/bin" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi

########################################
# COMPLETION FOR TERRAFORM             #
########################################

# Enable terraform autocomplete
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

########################################
# ADDITIONAL PATHS                      #
########################################

export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/.config/emacs/bin"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$PATH:$HOME/.local/share/nvim/mason/"

########################################
# MORE ALIASES                          #
########################################

alias tf='terraform'
alias vi='nvim'
alias vim='nvim'
alias lll='ls -lah'

#######################################################################
# END OF FILE                                                         #
# Maintain clarity – add new items above and keep this footer intact. #
#######################################################################