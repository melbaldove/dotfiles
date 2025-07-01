#!/usr/bin/env bash

set -e

# WireGuard setup script for Darwin using agenix
echo "Setting up WireGuard on macOS with agenix..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if agenix is available
if ! command -v agenix &> /dev/null; then
    echo -e "${RED}agenix not found. Please rebuild your system first.${NC}"
    exit 1
fi

# Navigate to secrets directory
cd "/Users/melbournebaldove/.dotfiles/secrets"

echo -e "${YELLOW}Decrypting Turing's WireGuard private key...${NC}"

# Decrypt the private key
private_key=$(agenix -d wireguard-turing-private.age)

if [[ -z "$private_key" ]]; then
    echo -e "${RED}Failed to decrypt private key${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating WireGuard configuration...${NC}"

# Create WireGuard config directory
sudo mkdir -p /etc/wireguard

# Create the config file with the decrypted key
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
PrivateKey = $private_key
Address = 10.0.0.3/24
DNS = 1.1.1.1

[Peer]
PublicKey = 8jFBCynKH6dwA/T/duyIg7n2GSaC1gBsjJREYjWdyU4=
AllowedIPs = 10.0.0.0/24, 192.168.50.0/24
Endpoint = shannon:51820
PersistentKeepalive = 25
EOF

# Set correct permissions
sudo chmod 600 /etc/wireguard/wg0.conf

echo -e "${GREEN}✓ WireGuard configuration created successfully${NC}"
echo -e "${YELLOW}To start the VPN:${NC} sudo wg-quick up wg0"
echo -e "${YELLOW}To stop the VPN:${NC} sudo wg-quick down wg0"

# Test if we should remove the old config
if [[ -f "/usr/local/etc/wireguard/wg0.conf" ]]; then
    echo -e "${YELLOW}Found old WireGuard config at /usr/local/etc/wireguard/wg0.conf${NC}"
    echo "You can remove it with: sudo rm /usr/local/etc/wireguard/wg0.conf"
fi