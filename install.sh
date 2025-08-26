#!/bin/bash

# Install dotfiles script with enhanced logging

# Exit on error
set -e

# Logging setup
LOG_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dotfiles-install.log"
VERBOSE=0

# Logging function
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
  
  # Write to log file
  echo "[$timestamp] $level: $message" >> "$LOG_FILE"
  
  # Output to console based on log level
  if [[ "$level" != "DEBUG" || "$VERBOSE" -eq 1 ]]; then
    echo "[$level] $message"
  fi
}

# Define source dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/dotconfig"
CONFIG_DEST="$HOME/.config"
DOTIGNORE_FILE="$DOTFILES_DIR/.dotignore"

# Initialize array to store tools to ignore
declare -A IGNORE_TOOLS

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ignore)
      shift
      log "DEBUG" "Processing --ignore flag with value: $1"
      for tool in $1; do
        IGNORE_TOOLS["$tool"]=1
      done
      shift
      ;;
    --verbose)
      VERBOSE=1
      log "INFO" "Verbose mode enabled"
      shift
      ;;
    --log-file)
      shift
      LOG_FILE="$1"
      log "INFO" "Log file set to $LOG_FILE"
      shift
      ;;
    *)
      log "ERROR" "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create log file directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
log "INFO" "Starting dotfiles installation"

# Read .dotignore file if it exists
if [ -f "$DOTIGNORE_FILE" ]; then
  log "INFO" "Reading ignore list from $DOTIGNORE_FILE"
  while IFS= read -r line; do
    # Skip empty lines or comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    line=$(echo "$line" | tr -d '[:space:]')
    log "DEBUG" "Ignoring tool: $line"
    IGNORE_TOOLS["$line"]=1
  done < "$DOTIGNORE_FILE"
else
  log "DEBUG" "No .dotignore file found at $DOTIGNORE_FILE"
fi

# Check if dotconfig directory exists
if [ ! -d "$CONFIG_SRC" ]; then
  log "ERROR" "dotconfig directory '$CONFIG_SRC' not found"
  exit 1
fi

# Create ~/.config if it doesn't exist
log "DEBUG" "Ensuring $CONFIG_DEST exists"
mkdir -p "$CONFIG_DEST"

# Install non-ignored tools
log "INFO" "Installing dotfiles..."
for tool_dir in "$CONFIG_SRC"/*; do
  # Skip if not a directory
  [ -d "$tool_dir" ] || {
    log "DEBUG" "Skipping $tool_dir (not a directory)"
    continue
  }
  tool_name=$(basename "$tool_dir")
  
  # Check if tool is in ignore list
  if [ "${IGNORE_TOOLS[$tool_name]}" -eq 1 ] 2>/dev/null; then
    log "INFO" "Skipping $tool_name (ignored)"
    continue
  fi
  
  # Install tool configuration
  log "INFO" "Installing $tool_name configuration..."
  log "DEBUG" "Creating directory $CONFIG_DEST/$tool_name"
  mkdir -p "$CONFIG_DEST/$tool_name"
  log "DEBUG" "Copying $tool_dir/. to $CONFIG_DEST/$tool_name/"
  cp -r "$tool_dir/." "$CONFIG_DEST/$tool_name/"
  log "INFO" "$tool_name configuration installed to $CONFIG_DEST/$tool_name"
done

log "INFO" "Dotfiles installation complete!"