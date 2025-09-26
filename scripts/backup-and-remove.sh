#!/usr/bin/env bash
set -Eeuo pipefail

# ── Dotfiles Backup and Removal Script ──
# This script backs up existing dotfiles and removes them before installation
# Usage: ./backup-and-remove.sh [--dry-run] [--force]

# ── Configuration ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${HOME}/.dotfiles-backup.log"

# ── Options ──
DRY_RUN=0
FORCE=0

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
    echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
}

# ── Files to backup and remove ──
DOTFILES_TO_REMOVE=(
    # Shell configurations
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.bash_aliases"
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.profile"
    
    # Editor configurations
    "$HOME/.vimrc"
    "$HOME/.vim"
    "$HOME/.config/nvim"
    "$HOME/.config/vim"
    
    # Terminal configurations
    "$HOME/.tmux.conf"
    "$HOME/.tmux"
    "$HOME/.config/tmux"
    
    # Git configurations
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    
    # Starship configuration
    "$HOME/.config/starship.toml"
    
    # Other common dotfiles
    "$HOME/.inputrc"
    "$HOME/.screenrc"
    "$HOME/.wgetrc"
    "$HOME/.curlrc"
    "$HOME/.dircolors"
    "$HOME/.lessrc"
    "$HOME/.selected_editor"
    
    # Development tool configurations
    "$HOME/.config/dotfiles"
    "$HOME/.local/share/dotfiles-remote"
    
    # Python configurations
    "$HOME/.pythonrc"
    "$HOME/.pylintrc"
    "$HOME/.flake8"
    "$HOME/.isort.cfg"
    
    # Node.js configurations
    "$HOME/.npmrc"
    "$HOME/.nvmrc"
    
    # Rust configurations
    "$HOME/.cargo/config.toml"
    
    # SSH configurations (be careful with this)
    # "$HOME/.ssh/config"
    # "$HOME/.ssh/known_hosts"
)

# ── Directories to backup and remove ──
DIRECTORIES_TO_REMOVE=(
    "$HOME/.config/dotfiles"
    "$HOME/.local/share/dotfiles-remote"
    "$HOME/.vim"
    "$HOME/.tmux"
    "$HOME/.config/tmux"
    "$HOME/.config/nvim"
    "$HOME/.config/vim"
)

# ── Backup function ──
backup_file() {
    local file="$1"
    local backup_path="$2"
    
    if [[ -f "$file" ]] || [[ -d "$file" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
            log_debug "[DRY RUN] Would backup $file to $backup_path"
            return 0
        fi
        
        mkdir -p "$(dirname "$backup_path")"
        
        if [[ -d "$file" ]]; then
            cp -r "$file" "$backup_path"
            log "Backed up directory $file to $backup_path"
        else
            cp "$file" "$backup_path"
            log "Backed up file $file to $backup_path"
        fi
        return 0
    fi
    return 1
}

# ── Remove function ──
remove_file() {
    local file="$1"
    
    if [[ -f "$file" ]] || [[ -d "$file" ]] || [[ -L "$file" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
            log_debug "[DRY RUN] Would remove $file"
            return 0
        fi
        
        if [[ -L "$file" ]]; then
            rm -f "$file"
            log "Removed symlink $file"
        elif [[ -d "$file" ]]; then
            rm -rf "$file"
            log "Removed directory $file"
        else
            rm -f "$file"
            log "Removed file $file"
        fi
        return 0
    fi
    return 1
}

# ── Check if file is important ──
is_important_file() {
    local file="$1"
    
    # Check if file contains important customizations
    if [[ -f "$file" ]]; then
        # Check for custom functions, aliases, or important configurations
        if grep -q "function\|alias\|export.*PATH\|export.*HOME" "$file" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# ── Interactive confirmation ──
confirm_removal() {
    local file="$1"
    
    if [[ "$FORCE" == "1" ]]; then
        return 0
    fi
    
    if is_important_file "$file"; then
        echo -e "${YELLOW}Warning: $file appears to contain customizations.${NC}"
        read -p "Do you want to remove it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            log_warn "Skipping $file (user declined)"
            return 1
        fi
    fi
    return 0
}

# ── Main backup and removal function ──
backup_and_remove() {
    log "Starting backup and removal process..."
    log "Backup directory: $BACKUP_DIR"
    log "Log file: $LOG_FILE"
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log "DRY RUN MODE - No actual changes will be made"
    fi
    
    # Create backup directory
    if [[ "$DRY_RUN" == "0" ]]; then
        mkdir -p "$BACKUP_DIR"
    fi
    
    local backed_up=0
    local removed=0
    local skipped=0
    
    # Process files
    for file in "${DOTFILES_TO_REMOVE[@]}"; do
        if [[ -f "$file" ]] || [[ -d "$file" ]] || [[ -L "$file" ]]; then
            local basename_file=$(basename "$file")
            local backup_path="$BACKUP_DIR/$basename_file"
            
            # Confirm removal for important files
            if ! confirm_removal "$file"; then
                ((skipped++))
                continue
            fi
            
            # Backup the file
            if backup_file "$file" "$backup_path"; then
                ((backed_up++))
                
                # Remove the original
                if remove_file "$file"; then
                    ((removed++))
                fi
            fi
        fi
    done
    
    # Process directories
    for dir in "${DIRECTORIES_TO_REMOVE[@]}"; do
        if [[ -d "$dir" ]]; then
            local basename_dir=$(basename "$dir")
            local backup_path="$BACKUP_DIR/$basename_dir"
            
            # Confirm removal for important directories
            if ! confirm_removal "$dir"; then
                ((skipped++))
                continue
            fi
            
            # Backup the directory
            if backup_file "$dir" "$backup_path"; then
                ((backed_up++))
                
                # Remove the original
                if remove_file "$dir"; then
                    ((removed++))
                fi
            fi
        fi
    done
    
    # Summary
    echo
    log "Backup and removal completed!"
    log "Files backed up: $backed_up"
    log "Files removed: $removed"
    log "Files skipped: $skipped"
    
    if [[ "$DRY_RUN" == "0" ]]; then
        log "Backup location: $BACKUP_DIR"
        log "Log file: $LOG_FILE"
        
        # Show backup contents
        if [[ -d "$BACKUP_DIR" ]] && [[ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
            echo
            echo -e "${CYAN}Backed up files:${NC}"
            ls -la "$BACKUP_DIR"
        fi
    fi
}

# ── Restore function ──
restore_backup() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory not found: $backup_dir"
        exit 1
    fi
    
    log "Restoring from backup: $backup_dir"
    
    local restored=0
    
    for item in "$backup_dir"/*; do
        if [[ -e "$item" ]]; then
            local basename_item=$(basename "$item")
            local target_path="$HOME/$basename_item"
            
            if [[ "$DRY_RUN" == "1" ]]; then
                log_debug "[DRY RUN] Would restore $item to $target_path"
            else
                if [[ -d "$item" ]]; then
                    cp -r "$item" "$target_path"
                    log "Restored directory $basename_item"
                else
                    cp "$item" "$target_path"
                    log "Restored file $basename_item"
                fi
            fi
            ((restored++))
        fi
    done
    
    log "Restored $restored items from backup"
}

# ── List available backups ──
list_backups() {
    local backup_base="${HOME}/.dotfiles-backup-"
    
    echo -e "${CYAN}Available backups:${NC}"
    for backup in "$HOME"/.dotfiles-backup-*; do
        if [[ -d "$backup" ]]; then
            local timestamp=$(basename "$backup" | sed 's/\.dotfiles-backup-//')
            local date_str=$(date -d "$timestamp" 2>/dev/null || echo "Unknown date")
            echo "  $backup ($date_str)"
        fi
    done
}

# ── Help function ──
show_help() {
    cat << EOF
Dotfiles Backup and Removal Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    --dry-run               Show what would be done without making changes
    --force                 Skip confirmation prompts
    --restore BACKUP_DIR    Restore from a specific backup directory
    --list-backups          List available backup directories
    --clean-old             Remove old backup directories (older than 30 days)

EXAMPLES:
    $0                      # Interactive backup and removal
    $0 --dry-run            # See what would be removed
    $0 --force              # Remove without confirmation
    $0 --restore ~/.dotfiles-backup-20240101-120000
    $0 --list-backups       # List available backups
    $0 --clean-old          # Clean up old backups

EOF
}

# ── Clean old backups ──
clean_old_backups() {
    local backup_base="${HOME}/.dotfiles-backup-"
    local cutoff_date=$(date -d "30 days ago" +%Y%m%d 2>/dev/null || echo "0")
    local removed=0
    
    log "Cleaning backups older than 30 days..."
    
    for backup in "$HOME"/.dotfiles-backup-*; do
        if [[ -d "$backup" ]]; then
            local timestamp=$(basename "$backup" | sed 's/\.dotfiles-backup-//')
            local backup_date=$(echo "$timestamp" | cut -d'-' -f1)
            
            if [[ "$backup_date" -lt "$cutoff_date" ]]; then
                if [[ "$DRY_RUN" == "1" ]]; then
                    log_debug "[DRY RUN] Would remove old backup: $backup"
                else
                    rm -rf "$backup"
                    log "Removed old backup: $backup"
                fi
                ((removed++))
            fi
        fi
    done
    
    log "Cleaned $removed old backup directories"
}

# ── Parse command line arguments ──
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --force)
                FORCE=1
                shift
                ;;
            --restore)
                if [[ -n "${2:-}" ]]; then
                    restore_backup "$2"
                    exit 0
                else
                    log_error "Backup directory required for --restore"
                    exit 1
                fi
                ;;
            --list-backups)
                list_backups
                exit 0
                ;;
            --clean-old)
                clean_old_backups
                exit 0
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
    backup_and_remove
fi
