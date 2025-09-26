#!/usr/bin/env bash
# Main dotfiles installer

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Dotfiles Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    --full                  Full installation (default)
    --minimal               Minimal installation (just dotfiles)

EXAMPLES:
    $0 --full               # Full installation
    $0 --minimal            # Just install dotfiles
EOF
}

main() {
    local option="${1:-full}"
    case "$option" in
        --help|-h)
            show_help
            exit 0
            ;;
        --full)
            log "Running full installation..."
            "$SCRIPT_DIR/scripts/install.sh"
            ;;
        --minimal)
            log "Running minimal installation..."
            "$SCRIPT_DIR/scripts/install.sh" --minimal
            ;;
        *)
            log_error "Unknown option: $option"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
