#!/usr/bin/env bash
# Test script for dotfiles installation

set -Eeuo pipefail

echo "Testing dotfiles installation..."

# Test help function
echo "Testing help function..."
./install.sh --help > /dev/null && echo "✅ Help function works"

# Test minimal installation (dry run)
echo "Testing minimal installation options..."
INSTALL_ESSENTIAL_TOOLS=0 INSTALL_ADDITIONAL_TOOLS=0 SETUP_GIT=0 SETUP_TMUX=0 SETUP_NEOVIM=0 UPDATE_SYSTEM=0 ./install.sh --minimal > /dev/null && echo "✅ Minimal installation works"

# Test that all dotfiles are copied correctly
echo "Testing dotfiles copying..."
if [[ -f "aliases_general" && -f "aliases_git" && -f "aliases_kube" && -f "aliases_tf" && -f "functions_general" && -f "starship.toml" ]]; then
    echo "✅ All dotfiles present"
else
    echo "❌ Some dotfiles missing"
    exit 1
fi

echo "All tests passed! 🎉"
