# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles managed with Nix/nix-darwin and Home Manager on macOS. Uses flake-based configuration for reproducible system management.

## Architecture

- **nix/**: Nix configuration files
  - `flake.nix`: Main flake with system "Turing" 
  - `configuration.nix`: System-level nix-darwin config
  - `home.nix`: User-level Home Manager config

- **emacs/**: Emacs configuration files (symlinked to `~/.config/emacs/`)
- **ghostty/**: Terminal configuration  
- **git/**: Git configuration files
- **.claude-global/**: Claude Code configuration (symlinked to `~/.claude/`)

## Development Commands

```bash
# Rebuild system configuration
sudo darwin-rebuild --impure switch

# Update Home Manager only
home-manager switch

# Update dependencies
nix flake update
```

## Key Features

- **Hybrid package management**: Nix packages + Homebrew casks + npm globals
- **File symlinking**: Home Manager creates symlinks from dotfiles to proper locations
- **Development tools**: ast-grep (alias: `sg`), ripgrep, gh, aider-chat, claude-code
- **Custom setup**: Colemak keyboard, Emacs daemon, global gitignore

## Important Notes

- Generated files live in their proper locations (`~/.config/emacs/`, etc.)
- Only configuration files are tracked in this repo
- Use `ast-grep` for syntax-aware code searching when available