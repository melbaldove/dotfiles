#!/usr/bin/env bash

# Manual setup script for macOS system dependencies
# Run this once after initial nix-darwin installation

echo "Setting up macOS system dependencies..."

# Install Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
else
    echo "Xcode Command Line Tools already installed"
fi

# Install Rosetta 2 for Apple Silicon Macs
if [[ $(uname -m) == "arm64" ]]; then
    if ! pgrep -q oahd; then
        echo "Installing Rosetta 2..."
        softwareupdate --install-rosetta --agree-to-license
    else
        echo "Rosetta 2 already installed"
    fi
fi

echo "System setup complete!"