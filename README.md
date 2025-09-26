# Dotfiles Project

A comprehensive dotfiles management system with backup, removal, and installation capabilities.

## Quick Start

```bash
# Full installation (backup, remove, install)
./main-install.sh --full

# Minimal installation (just dotfiles)
./main-install.sh --minimal

# Just backup existing files
./scripts/backup-and-remove.sh --dry-run
```

## Project Structure

```
dotfiles/
├── main-install.sh         # Main installer script
├── scripts/                # Installation and management scripts
│   ├── install.sh         # Comprehensive installation script
│   ├── setup-dotfiles.sh  # Minimal dotfiles installer
│   ├── backup-and-remove.sh # Backup and removal script
│   └── test-install.sh    # Test script
├── aliases/               # Shell aliases
│   ├── aliases_general
│   ├── aliases_git
│   ├── aliases_kube
│   └── aliases_tf
├── functions/             # Shell functions
│   └── functions_general
├── config/               # Configuration files
│   └── starship.toml
├── docs/                 # Documentation
│   ├── README.md
│   ├── CONTRIBUTING.md
│   └── LICENSE
└── examples/             # Example configurations
```

## Features

- **Backup System**: Automatically backs up existing dotfiles
- **Safe Removal**: Removes old dotfiles with confirmation
- **Comprehensive Installation**: Installs tools, configures shells, sets up development environment
- **Modular Design**: Organized into logical directories
- **Multiple Installation Modes**: Full, minimal, backup-only, etc.

## Installation Options

- `--full`: Complete installation with backup and removal
- `--minimal`: Just install dotfiles without system tools

## What Gets Installed

- **Active dir (symlink targets loaded by `.bashrc`):**
  `~/.config/dotfiles/`

- **Backup dir for existing files:**
  `~/.dotfiles-backup-YYYYMMDD-HHMMSS/`

Your repo content includes:

- `aliases_general`, `aliases_git`, `aliases_kube`, `aliases_tf` - Shell aliases
- `functions_general` - Shell functions
- `starship.toml` - Starship prompt configuration

## Using the aliases (examples)

```bash
ll         # ls -lh with grouping & color
gst        # git status -sb
kgn        # kubectl get nodes -o wide
tfp        # terraform plan
mkcd foo   # mkdir -p foo && cd foo
```

## Requirements

- Bash 4.0+
- curl
- git
- sudo (for system package installation)

## Troubleshooting

If you encounter function syntax errors, restart your shell:

```bash
source ~/.bashrc
# or
exec bash
```

## License

See [LICENSE](docs/LICENSE) for details.
