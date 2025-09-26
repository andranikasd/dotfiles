#!/usr/bin/env bash
# Cleanup script to remove dangling symlinks and old files

set -Eeuo pipefail

DOTFILES_DIR="${HOME}/.config/dotfiles"

log() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

cleanup_dotfiles() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log "Dotfiles directory not found: $DOTFILES_DIR"
        return 0
    fi
    
    log "Cleaning up dotfiles directory: $DOTFILES_DIR"
    
    # Remove dangling symlinks
    find "$DOTFILES_DIR" -type l ! -exec test -e {} \; -delete
    log "Removed dangling symlinks"
    
    # Remove any backup files
    find "$DOTFILES_DIR" -name "*.backup.*" -delete
    log "Removed backup files"
    
    # List remaining files
    log "Remaining files in dotfiles directory:"
    ls -la "$DOTFILES_DIR"
}

main() {
    cleanup_dotfiles
    log "Cleanup completed!"
}

main "$@"
