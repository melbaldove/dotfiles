
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles managed with Nix. Uses a flake-based, modular configuration for multi-machine and multi-OS system management.

## Architecture

- **`flake.nix`**: The root flake. It defines all installable outputs (hosts).
- **`hosts/`**: Contains the entrypoints for each machine configuration.
  - `turing/`: A macOS machine.
- **`modules/`**: Contains reusable system-level configurations.
  - `system/darwin/`: macOS-specific modules.
  - `system/linux/`: Linux-specific modules.
  - `system/shared/`: OS-agnostic modules.
- **`users/`**: Contains composable user profiles.
  - `melbournebaldove/`: Your user profiles (`core`, `dev`).

## Development Commands

```bash
# Rebuild the 'Turing' system configuration
sudo darwin-rebuild --impure switch --flake .#Turing

# Update dependencies
nix flake update
```

## Important Notes

- The configuration is highly modular. When making changes, identify whether the change is for a specific host, a shared system module, or a user profile.
- Use `ast-grep` for syntax-aware code searching.
