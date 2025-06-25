# Dotfiles

Personal macOS configuration managed with Nix and Home Manager.

## Quick Start

```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Apply configuration
sudo darwin-rebuild switch --flake github:melbournebaldove/dotfiles#Turing
```

## Local Development

```bash
git clone https://github.com/melbournebaldove/dotfiles ~/.dotfiles
cd ~/.dotfiles

# System changes
sudo darwin-rebuild switch --flake nix#Turing

# Home Manager only
home-manager switch --flake nix#melbournebaldove@Turing

# Update dependencies
nix flake update nix/
```

## Structure

- `nix/` - Nix configuration files
- `emacs/` - Emacs configuration
- `git/` - Git configuration  
- `ghostty/` - Terminal configuration

Configurations are symlinked to proper locations via Home Manager.