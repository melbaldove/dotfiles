# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles managed with Nix. Uses a flake-based, modular configuration for multi-machine and multi-OS system management.

## Architecture

- **`flake.nix`**: The root flake. It defines all installable outputs (hosts) and all external dependencies (inputs).
- **`hosts/`**: Contains the entrypoints for each machine configuration.
- **`modules/`**: Contains reusable system-level configurations.
- **`users/`**: Contains composable user profiles.

## Configuration Guidelines

When adding or changing a configuration, use the following guidelines to determine the correct location:

- **`hosts/`**: Use this directory to define a new machine. A host file should not contain any real configuration logic. Its only job is to `import` the necessary modules from `modules/` and `users/` to assemble a complete system.

- **`modules/`**: This is for system-level configuration that can be shared between machines.
  - **`modules/system/shared/`**: For settings that apply to *all* systems (e.g., core packages, Nix settings).
  - **`modules/system/darwin/`**: For settings that only apply to macOS (e.g., Homebrew, macOS defaults).
  - **`modules/system/linux/`**: For settings that only apply to Linux (e.g., filesystem options, bootloader).

- **`users/`**: This is for user-specific configuration (Home Manager settings).
  - **`users/melbournebaldove/core.nix`**: Your base settings that you want on *every* machine (e.g., Git config, shell aliases).
  - **`users/melbournebaldove/dev.nix`**: Settings for your development environment (e.g., Emacs, programming languages).
  - Create new files here to define different roles (e.g., `server.nix` for headless servers).

## Available Hosts

- **`turing`**: macOS development machine (aarch64-darwin)
- **`einstein`**: Linux home server (x86_64-linux)

## Development Commands

```bash
# Rebuild the 'turing' macOS system configuration
sudo darwin-rebuild switch --flake .#turing

# Rebuild the 'einstein' NixOS home server configuration
sudo nixos-rebuild switch --flake .#einstein

# Update dependencies
nix flake update

# Initial macOS setup (run once)
./scripts/setup-darwin.sh
```