
# Dotfiles

My personal system configurations, managed declaratively with Nix.

## Overview

This repository uses a modular, flake-based approach to manage configurations for multiple machines and operating systems (macOS and Linux).

- **Declarative**: The entire system state is defined in code.
- **Reproducible**: Easily bootstrap a new machine to a known state.
- **Modular**: Configurations are broken down into reusable components for systems and users.

## Installation

1.  **Install Nix:**

    ```bash
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    ```

2.  **Apply the Configuration:**

    To provision a new machine, apply the desired host configuration from this repository.

    ```bash
    # For the 'turing' macOS configuration
    sudo darwin-rebuild switch --flake github:melbaldove/dotfiles#turing
    ```

## Local Development

```bash
# Clone the repository
cd ~/.dotfiles

# Rebuild the system
sudo darwin-rebuild switch --flake .#turing

# Update dependencies
nix flake update
```

## Structure

- **`flake.nix`**: The root flake that defines all machine configurations.
- **`hosts/`**: Contains the entrypoint for each machine.
- **`modules/`**: Reusable system-level configurations (for macOS, Linux, etc.).
- **`users/`**: Composable user profiles (e.g., a base profile, a developer profile).
- **`secrets/`**: Encrypted secrets managed with agenix.
- **`scripts/`**: Utility scripts for setup and testing.
