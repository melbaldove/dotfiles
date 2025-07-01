#!/usr/bin/env bash

# Generate WireGuard keys for all hosts

echo "Generating WireGuard keys..."
echo

# Generate keys for Shannon (VPN server)
echo "=== Shannon (VPN Server) ==="
shannon_private=$(wg genkey)
shannon_public=$(echo "$shannon_private" | wg pubkey)
echo "Private key: $shannon_private"
echo "Public key:  $shannon_public"
echo

# Generate keys for Einstein (Gateway)
echo "=== Einstein (Gateway) ==="
einstein_private=$(wg genkey)
einstein_public=$(echo "$einstein_private" | wg pubkey)
echo "Private key: $einstein_private"
echo "Public key:  $einstein_public"
echo

# Generate keys for Turing (Client)
echo "=== Turing (Client) ==="
turing_private=$(wg genkey)
turing_public=$(echo "$turing_private" | wg pubkey)
echo "Private key: $turing_private"
echo "Public key:  $turing_public"
echo

echo "=== Next Steps ==="
echo "1. Save the private keys securely on each host:"
echo "   - Shannon: echo '$shannon_private' | sudo tee /etc/wireguard/private"
echo "   - Einstein: echo '$einstein_private' | sudo tee /etc/wireguard/private"
echo "   - Turing: Save for client configuration"
echo
echo "2. Update the configuration files with the public keys:"
echo "   - In wireguard-server.nix:"
echo "     - Replace EINSTEIN_PUBLIC_KEY_PLACEHOLDER with: $einstein_public"
echo "     - Replace TURING_PUBLIC_KEY_PLACEHOLDER with: $turing_public"
echo "   - In wireguard-gateway.nix:"
echo "     - Replace SHANNON_PUBLIC_KEY_PLACEHOLDER with: $shannon_public"
echo
echo "3. Update SHANNON_IP_ADDRESS in wireguard-gateway.nix with Shannon's actual IP"