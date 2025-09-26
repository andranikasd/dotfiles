#!/usr/bin/env bash
set -Eeuo pipefail

# ── Comprehensive Dotfiles Installation Script ──
# This script sets up a complete development environment with:
# - Essential tools (neovim, fzf, python, etc.)
# - Shell enhancements (bash, zsh support)
# - Terminal multiplexer (tmux)
# - Git configuration
# - Dotfiles management
# - Starship prompt
# - And much more...

# ── Configuration ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${HOME}/.config/dotfiles"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${HOME}/.dotfiles-install.log"

# ── Installation Options ──
INSTALL_ESSENTIAL_TOOLS="${INSTALL_ESSENTIAL_TOOLS:-1}"
INSTALL_ADDITIONAL_TOOLS="${INSTALL_ADDITIONAL_TOOLS:-1}"
SETUP_SHELL="${SETUP_SHELL:-1}"
SETUP_GIT="${SETUP_GIT:-1}"
SETUP_TMUX="${SETUP_TMUX:-1}"
SETUP_NEOVIM="${SETUP_NEOVIM:-1}"
SETUP_STARSHIP="${SETUP_STARSHIP:-1}"
UPDATE_SYSTEM="${UPDATE_SYSTEM:-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Logging Functions ──
log() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
    fi
}

# ── Utility Functions ──
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_mac() {
    [[ "$OSTYPE" == "darwin"* ]]
}

is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]]
}

# ── Package Manager Detection ──
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists brew; then
        echo "brew"
    elif command_exists zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# ── System Information ──
PACKAGE_MANAGER=$(detect_package_manager)
log "Detected package manager: $PACKAGE_MANAGER"

# ── Backup Function ──
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        log "Backed up $file to $BACKUP_DIR"
    fi
}

# ── Update System Packages ──
update_system() {
    log "Updating system packages..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt-get update && sudo apt-get upgrade -y
            ;;
        "yum")
            sudo yum update -y
            ;;
        "dnf")
            sudo dnf update -y
            ;;
        "pacman")
            sudo pacman -Syu --noconfirm
            ;;
        "brew")
            brew update && brew upgrade
            ;;
        "zypper")
            sudo zypper refresh && sudo zypper update -y
            ;;
        *)
            log_warn "Unknown package manager, skipping system update"
            ;;
    esac
}

# ── Install Essential Tools ──
install_essential_tools() {
    log "Installing essential development tools..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt-get install -y \
                curl wget git vim neovim \
                python3 python3-pip python3-venv \
                build-essential cmake \
                fzf ripgrep fd-find bat \
                tmux tree htop \
                jq unzip zip \
                openssh-client \
                ca-certificates \
                software-properties-common \
                apt-transport-https
            ;;
        "yum")
            sudo yum install -y \
                curl wget git vim neovim \
                python3 python3-pip \
                gcc gcc-c++ make cmake \
                fzf ripgrep fd-find bat \
                tmux tree htop \
                jq unzip zip \
                openssh-clients
            ;;
        "dnf")
            sudo dnf install -y \
                curl wget git vim neovim \
                python3 python3-pip \
                gcc gcc-c++ make cmake \
                fzf ripgrep fd-find bat \
                tmux tree htop \
                jq unzip zip \
                openssh-clients
            ;;
        "pacman")
            sudo pacman -S --noconfirm \
                curl wget git vim neovim \
                python python-pip \
                base-devel cmake \
                fzf ripgrep fd bat \
                tmux tree htop \
                jq unzip zip \
                openssh
            ;;
        "brew")
            brew install \
                git vim neovim \
                python@3.11 \
                cmake \
                fzf ripgrep fd bat \
                tmux tree htop \
                jq
            ;;
        *)
            log_warn "Unknown package manager, please install tools manually"
            ;;
    esac
}

# ── Install Node.js ──
install_nodejs() {
    if ! command_exists node; then
        log "Installing Node.js..."
        
        if is_mac; then
            brew install node
        else
            # Install NodeSource repository
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    else
        log "Node.js already installed"
    fi
}

# ── Install Rust ──
install_rust() {
    if ! command_exists cargo; then
        log "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        log "Rust already installed"
    fi
}

# ── Install Starship Prompt ──
install_starship() {
    if ! command_exists starship; then
        log "Installing Starship prompt..."
        
        if is_mac; then
            brew install starship
        else
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
    else
        log "Starship already installed"
    fi
}

# ── Install Additional Tools ──
install_additional_tools() {
    log "Installing additional useful tools..."
    
    # Install GitHub CLI
    if ! command_exists gh; then
        if is_mac; then
            brew install gh
        else
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh
        fi
    fi
    
    # Install Terraform
    if ! command_exists terraform; then
        log "Installing Terraform..."
        if is_mac; then
            brew install terraform
        else
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update
            sudo apt install terraform
        fi
    fi
    
    # Install Terragrunt
    if ! command_exists terragrunt; then
        log "Installing Terragrunt..."
        if is_mac; then
            brew install terragrunt
        else
            wget https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64 -O /tmp/terragrunt
            sudo mv /tmp/terragrunt /usr/local/bin/terragrunt
            sudo chmod +x /usr/local/bin/terragrunt
        fi
    fi
    
    # Install AWS CLI
    if ! command_exists aws; then
        log "Installing AWS CLI..."
        if is_mac; then
            brew install awscli
        else
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        fi
    fi
    
    # Install kubectl
    if ! command_exists kubectl; then
        log "Installing kubectl..."
        if is_mac; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
        fi
    fi
    
    # Install Docker (if not present)
    if ! command_exists docker; then
        log "Docker not found. You may want to install it manually."
    fi
    
    # Install Helm
    if ! command_exists helm; then
        log "Installing Helm..."
        if is_mac; then
            brew install helm
        else
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        fi
    fi
    
    # Install k9s (Kubernetes TUI)
    if ! command_exists k9s; then
        log "Installing k9s..."
        if is_mac; then
            brew install k9s
        else
            wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz -O /tmp/k9s.tar.gz
            tar -xzf /tmp/k9s.tar.gz -C /tmp
            sudo mv /tmp/k9s /usr/local/bin/k9s
            sudo chmod +x /usr/local/bin/k9s
            rm /tmp/k9s.tar.gz
        fi
    fi
}

# ── Setup Python Environment ──
setup_python() {
    log "Setting up Python environment..."
    
    # Create virtual environment
    if [[ ! -d "$HOME/.venv" ]]; then
        python3 -m venv "$HOME/.venv"
        log "Created Python virtual environment at $HOME/.venv"
    fi
    
    # Install common Python packages
    "$HOME/.venv/bin/pip" install --upgrade pip
    "$HOME/.venv/bin/pip" install \
        black flake8 isort \
        requests click \
        jupyter notebook \
        pandas numpy matplotlib
}

# ── Setup Git Configuration ──
setup_git() {
    log "Setting up Git configuration..."
    
    # Set up Git user if not configured
    if ! git config --global user.name >/dev/null 2>&1; then
        read -p "Enter your Git username: " git_username
        git config --global user.name "$git_username"
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Set up Git aliases and configuration
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global push.autoSetupRemote true
    git config --global core.editor "nvim"
    git config --global color.ui auto
    git config --global diff.tool "nvim -d"
    git config --global merge.tool "nvim -d"
}

# ── Setup Shell Environment ──
setup_shell() {
    log "Setting up shell environment..."
    
    # Create dotfiles directory
    mkdir -p "$DOTFILES_DIR"
    
    # Copy all dotfiles to the config directory
    log "Copying dotfiles to $DOTFILES_DIR..."
    
    # Copy starship configuration
    if [[ -f "$SCRIPT_DIR/../config/starship.toml" ]]; then
        # Remove existing file/symlink if it exists
        if [[ -e "$DOTFILES_DIR/starship.toml" ]]; then
            rm -f "$DOTFILES_DIR/starship.toml"
        fi
        cp "$SCRIPT_DIR/../config/starship.toml" "$DOTFILES_DIR/"
        log "Copied starship.toml"
    fi
    
    # Copy all aliases files
    for file in "$SCRIPT_DIR"/../aliases/aliases_*; do
        if [[ -f "$file" ]]; then
            # Remove existing file/symlink if it exists
            if [[ -e "$DOTFILES_DIR/$(basename "$file")" ]]; then
                rm -f "$DOTFILES_DIR/$(basename "$file")"
            fi
            cp "$file" "$DOTFILES_DIR/"
            log "Copied $(basename "$file")"
        fi
    done
    
    # Copy all functions files
    for file in "$SCRIPT_DIR"/../functions/functions_*; do
        if [[ -f "$file" ]]; then
            # Remove existing file/symlink if it exists
            if [[ -e "$DOTFILES_DIR/$(basename "$file")" ]]; then
                rm -f "$DOTFILES_DIR/$(basename "$file")"
            fi
            cp "$file" "$DOTFILES_DIR/"
            log "Copied $(basename "$file")"
        fi
    done
    
    # Setup bash configuration
    setup_bash_config
    
    # Setup zsh configuration (if zsh is installed)
    if command_exists zsh; then
        setup_zsh_config
    fi
    
    # Setup starship configuration
    if [[ "$SETUP_STARSHIP" == "1" ]]; then
        setup_starship_config
    fi
}

# ── Setup Bash Configuration ──
setup_bash_config() {
    log "Setting up Bash configuration..."
    
    local bashrc_file="$HOME/.bashrc"
    backup_file "$bashrc_file"
    
    # Create enhanced bashrc
    cat > "$bashrc_file" << 'EOF'
# ~/.bashrc - Enhanced Bash Configuration

# ── Basic Settings ──
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize
shopt -s globstar
shopt -s dotglob
shopt -s extglob

# ── Path Configuration ──
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.venv/bin:$PATH"

# ── Editor Configuration ──
export EDITOR="nvim"
export VISUAL="nvim"

# ── Color Support ──
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ── Aliases and Functions Loader ──
DOTFILES_DIR="$HOME/.config/dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
    shopt -s nullglob
    for file in "$DOTFILES_DIR"/aliases_* "$DOTFILES_DIR"/functions_*; do
        [ -f "$file" ] && . "$file"
    done
    shopt -u nullglob
fi

# ── FZF Configuration ──
if command -v fzf >/dev/null 2>&1; then
    # FZF key bindings
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.bash
    elif [[ -f /usr/local/share/fzf/shell/key-bindings.bash ]]; then
        source /usr/local/share/fzf/shell/key-bindings.bash
    fi
    
    # FZF completion
    if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
        source /usr/share/doc/fzf/examples/completion.bash
    elif [[ -f /usr/local/share/fzf/shell/completion.bash ]]; then
        source /usr/local/share/fzf/shell/completion.bash
    fi
    
    # Enhanced FZF settings
    export FZF_DEFAULT_OPTS='
        --height 40%
        --layout=reverse
        --border
        --preview-window=right:60%:wrap
        --bind=ctrl-/:toggle-preview
        --bind=ctrl-y:execute-silent(echo {} | pbcopy)
        --bind=ctrl-k:kill-line
        --bind=ctrl-u:clear-query
        --bind=ctrl-w:backward-kill-word
        --bind=ctrl-space:toggle
        --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
        --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
        --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
        --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
    '
    
    # FZF commands
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    
    # Enhanced FZF key bindings
    # Ctrl+R: Enhanced history search with preview
    __fzf_history__() {
        local output
        output=$(fc -lnr -2147483648 | fzf --tac --no-sort --exact --preview 'echo {}' --preview-window down:3:wrap --query="$READLINE_LINE") &&
        READLINE_LINE=${output}
        READLINE_POINT=${#READLINE_LINE}
    }
    bind -m emacs-standard -x '"\C-r": __fzf_history__'
    bind -m vi-command -x '"\C-r": __fzf_history__'
    bind -m vi-insert -x '"\C-r": __fzf_history__'
    
    # Ctrl+T: Enhanced file search with preview
    __fzf_file__() {
        local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
            -o -type f -print -o -type d -print -o -type l -print 2> /dev/null | cut -b3-"}"
        local out
        out=$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf --preview 'bat --color=always --style=header,grid --line-range :300 {}' --preview-window right:60%:wrap) &&
        printf '%q ' "$out"
    }
    bind -m emacs-standard -x '"\C-t": __fzf_file__'
    bind -m vi-command -x '"\C-t": __fzf_file__'
    bind -m vi-insert -x '"\C-t": __fzf_file__'
    
    # Alt+C: Enhanced directory search with preview
    __fzf_cd__() {
        local cmd dir
        cmd="${FZF_ALT_C_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
            -o -type d -print 2> /dev/null | cut -b3-"}"
        dir=$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf --preview 'exa --tree --level=2 {}' --preview-window right:60%:wrap) &&
        printf 'cd %q' "$dir"
    }
    bind -m emacs-standard -x '"\ec": __fzf_cd__'
    bind -m vi-command -x '"\ec": __fzf_cd__'
    bind -m vi-insert -x '"\ec": __fzf_cd__'
fi

# ── Starship Prompt ──
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ── Custom Functions (loaded from dotfiles) ──
# Functions are loaded from ~/.config/dotfiles/functions_* files

# ── WSL Specific Configuration ──
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    # WSL-specific aliases
    alias winopen='explorer.exe .'
    alias clip='clip.exe'
    
    # Windows path in WSL
    export PATH="$PATH:/mnt/c/Windows/System32"
fi

# ── Load local configuration if it exists ──
if [[ -f "$HOME/.bashrc.local" ]]; then
    source "$HOME/.bashrc.local"
fi
EOF

    log "Bash configuration updated"
}

# ── Setup Zsh Configuration ──
setup_zsh_config() {
    log "Setting up Zsh configuration..."
    
    local zshrc_file="$HOME/.zshrc"
    backup_file "$zshrc_file"
    
    # Create zshrc with similar configuration
    cat > "$zshrc_file" << 'EOF'
# ~/.zshrc - Enhanced Zsh Configuration

# ── Basic Settings ──
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

# ── Path Configuration ──
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.venv/bin:$PATH"

# ── Editor Configuration ──
export EDITOR="nvim"
export VISUAL="nvim"

# ── Aliases and Functions Loader ──
DOTFILES_DIR="$HOME/.config/dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
    for file in "$DOTFILES_DIR"/aliases_* "$DOTFILES_DIR"/functions_*; do
        [ -f "$file" ] && . "$file"
    done
fi

# ── FZF Configuration ──
if command -v fzf >/dev/null 2>&1; then
    # FZF key bindings
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    elif [[ -f /usr/local/share/fzf/shell/key-bindings.zsh ]]; then
        source /usr/local/share/fzf/shell/key-bindings.zsh
    fi
    
    # FZF completion
    if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
        source /usr/share/doc/fzf/examples/completion.zsh
    elif [[ -f /usr/local/share/fzf/shell/completion.zsh ]]; then
        source /usr/local/share/fzf/shell/completion.zsh
    fi
    
    # FZF settings
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ── Starship Prompt ──
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ── Load local configuration if it exists ──
if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi
EOF

    log "Zsh configuration updated"
}

# ── Setup Tmux Configuration ──
setup_tmux() {
    log "Setting up Tmux configuration..."
    
    local tmux_conf="$HOME/.tmux.conf"
    backup_file "$tmux_conf"
    
    cat > "$tmux_conf" << 'EOF'
# ~/.tmux.conf - Enhanced Tmux Configuration

# ── General Settings ──
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g mouse on
set -g focus-events on
set -g default-shell /bin/bash

# ── Key Bindings ──
# Change prefix key to Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Resize panes using Ctrl-arrow
bind -n C-Left resize-pane -L 5
bind -n C-Right resize-pane -R 5
bind -n C-Up resize-pane -U 5
bind -n C-Down resize-pane -D 5

# ── Window Management ──
# Create new window
bind c new-window -c "#{pane_current_path}"

# Rename window
bind r command-prompt "rename-window %%"

# ── Status Bar ──
set -g status-position top
set -g status-justify left
set -g status-style 'bg=#1e1e1e fg=#ffffff'
set -g status-left-length 40
set -g status-left '#[fg=#00ff00]#S #[fg=#ffffff]| '
set -g status-right-length 60
set -g status-right '#[fg=#ffffff]%Y-%m-%d %H:%M #[fg=#00ff00]#(whoami)@#h'

# ── Pane Border ──
set -g pane-border-style 'fg=#404040'
set -g pane-active-border-style 'fg=#00ff00'

# ── Window Status ──
setw -g window-status-style 'fg=#666666'
setw -g window-status-current-style 'fg=#00ff00 bold'
setw -g window-status-format ' #I:#W '
setw -g window-status-current-format ' #I:#W '

# ── Copy Mode ──
setw -g mode-style 'bg=#404040 fg=#ffffff'
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel
bind -T copy-mode-vi r send -X rectangle-toggle

# ── Plugins (if tpm is installed) ──
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Plugin settings
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOF

    # Install TPM (Tmux Plugin Manager) if not present
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        log "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
    
    log "Tmux configuration updated"
}

# ── Setup Neovim Configuration ──
setup_neovim() {
    log "Setting up Neovim configuration..."
    
    local nvim_dir="$HOME/.config/nvim"
    mkdir -p "$nvim_dir"
    
    # Create basic init.lua
    cat > "$nvim_dir/init.lua" << 'EOF'
-- ~/.config/nvim/init.lua - Basic Neovim Configuration

-- Leader key
vim.g.mapleader = " "

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.undofile = true
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

-- Key mappings
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Install lazy.nvim if not present
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Configure lazy.nvim
require("lazy").setup({
    -- Color scheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    
    -- File explorer
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("nvim-tree").setup({
                view = {
                    width = 30,
                },
            })
        end,
    },
    
    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.4",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
        end,
    },
    
    -- LSP
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "pyright", "tsserver" }
            })
        end,
    },
    
    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "lua", "python", "javascript", "typescript" },
                auto_install = true,
                highlight = {
                    enable = true,
                },
            })
        end,
    },
})
EOF

    log "Neovim configuration created"
}

# ── Setup Starship Configuration ──
setup_starship_config() {
    log "Setting up Starship configuration..."
    
    local starship_config_dir="$HOME/.config"
    mkdir -p "$starship_config_dir"
    
    # Copy starship configuration
    if [[ -f "$DOTFILES_DIR/starship.toml" ]]; then
        cp "$DOTFILES_DIR/starship.toml" "$starship_config_dir/"
        log "Starship configuration installed"
    else
        log_warn "Starship configuration not found in dotfiles"
    fi
}

# ── Main Installation Function ──
main() {
    log "Starting comprehensive dotfiles installation..."
    log "Backup directory: $BACKUP_DIR"
    log "Log file: $LOG_FILE"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Show installation options
    echo -e "${CYAN}Installation Options:${NC}"
    echo "  Essential Tools: $([ "$INSTALL_ESSENTIAL_TOOLS" == "1" ] && echo "✅" || echo "❌")"
    echo "  Additional Tools: $([ "$INSTALL_ADDITIONAL_TOOLS" == "1" ] && echo "✅" || echo "❌")"
    echo "  Shell Setup: $([ "$SETUP_SHELL" == "1" ] && echo "✅" || echo "❌")"
    echo "  Git Setup: $([ "$SETUP_GIT" == "1" ] && echo "✅" || echo "❌")"
    echo "  Tmux Setup: $([ "$SETUP_TMUX" == "1" ] && echo "✅" || echo "❌")"
    echo "  Neovim Setup: $([ "$SETUP_NEOVIM" == "1" ] && echo "✅" || echo "❌")"
    echo "  Starship Setup: $([ "$SETUP_STARSHIP" == "1" ] && echo "✅" || echo "❌")"
    echo "  System Update: $([ "$UPDATE_SYSTEM" == "1" ] && echo "✅" || echo "❌")"
    echo
    
    # Update system
    if [[ "$UPDATE_SYSTEM" == "1" ]]; then
        update_system
    fi
    
    # Install essential tools
    if [[ "$INSTALL_ESSENTIAL_TOOLS" == "1" ]]; then
        install_essential_tools
    fi
    
    # Install additional tools
    if [[ "$INSTALL_ADDITIONAL_TOOLS" == "1" ]]; then
        install_nodejs
        install_rust
        install_starship
        install_additional_tools
    fi
    
    # Setup environments
    if [[ "$SETUP_GIT" == "1" ]]; then
        setup_git
    fi
    
    if [[ "$SETUP_SHELL" == "1" ]]; then
        setup_shell
    fi
    
    if [[ "$SETUP_TMUX" == "1" ]]; then
        setup_tmux
    fi
    
    if [[ "$SETUP_NEOVIM" == "1" ]]; then
        setup_neovim
    fi
    
    # Setup Python environment
    setup_python
    
    log "Installation completed successfully!"
    log "Backup files are stored in: $BACKUP_DIR"
    log "Please restart your shell or run: source ~/.bashrc"
    
    # Show next steps
    echo
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Restart your shell or run: ${YELLOW}source ~/.bashrc${NC}"
    if [[ "$SETUP_TMUX" == "1" ]]; then
        echo "2. Install tmux plugins: ${YELLOW}tmux new-session -d '~/.tmux/plugins/tpm/scripts/install_plugins.sh'${NC}"
    fi
    if [[ "$SETUP_GIT" == "1" ]]; then
        echo "3. Configure your Git user info if not done already"
    fi
    echo "4. Enjoy your new development environment!"
    echo
    echo -e "${PURPLE}Your dotfiles are managed in: $DOTFILES_DIR${NC}"
    echo -e "${PURPLE}Backup files are in: $BACKUP_DIR${NC}"
    echo -e "${PURPLE}Log file: $LOG_FILE${NC}"
}

# ── Help Function ──
show_help() {
    cat << EOF
Dotfiles Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    --no-essential          Skip essential tools installation
    --no-additional         Skip additional tools installation
    --no-shell              Skip shell configuration
    --no-git                Skip Git configuration
    --no-tmux               Skip Tmux configuration
    --no-neovim             Skip Neovim configuration
    --no-starship           Skip Starship configuration
    --no-update             Skip system update
    --minimal               Install only essential components (shell + dotfiles)
    --full                  Install everything (default)

ENVIRONMENT VARIABLES:
    INSTALL_ESSENTIAL_TOOLS=0/1    Install essential tools (default: 1)
    INSTALL_ADDITIONAL_TOOLS=0/1   Install additional tools (default: 1)
    SETUP_SHELL=0/1                Setup shell configuration (default: 1)
    SETUP_GIT=0/1                  Setup Git configuration (default: 1)
    SETUP_TMUX=0/1                 Setup Tmux configuration (default: 1)
    SETUP_NEOVIM=0/1               Setup Neovim configuration (default: 1)
    SETUP_STARSHIP=0/1             Setup Starship configuration (default: 1)
    UPDATE_SYSTEM=0/1              Update system packages (default: 1)

EXAMPLES:
    $0                          # Full installation
    $0 --minimal                # Minimal installation
    $0 --no-tmux --no-neovim    # Skip tmux and neovim setup
    INSTALL_ADDITIONAL_TOOLS=0 $0  # Skip additional tools

EOF
}

# ── Parse Command Line Arguments ──
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --no-essential)
                INSTALL_ESSENTIAL_TOOLS=0
                shift
                ;;
            --no-additional)
                INSTALL_ADDITIONAL_TOOLS=0
                shift
                ;;
            --no-shell)
                SETUP_SHELL=0
                shift
                ;;
            --no-git)
                SETUP_GIT=0
                shift
                ;;
            --no-tmux)
                SETUP_TMUX=0
                shift
                ;;
            --no-neovim)
                SETUP_NEOVIM=0
                shift
                ;;
            --no-starship)
                SETUP_STARSHIP=0
                shift
                ;;
            --no-update)
                UPDATE_SYSTEM=0
                shift
                ;;
            --minimal)
                INSTALL_ESSENTIAL_TOOLS=0
                INSTALL_ADDITIONAL_TOOLS=0
                SETUP_GIT=0
                SETUP_TMUX=0
                SETUP_NEOVIM=0
                UPDATE_SYSTEM=0
                shift
                ;;
            --full)
                # Reset all to defaults (already set)
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ── Script Execution ──
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    main "$@"
fi
