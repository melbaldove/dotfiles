# Agenix Setup Guide for WireGuard Keys

## Step 1: Collect SSH Host Public Keys

Run these commands to get the host keys:

```bash
# Get einstein's host key (if you can SSH to it)
ssh-keyscan einstein 2>/dev/null | grep ed25519 | cut -d' ' -f2-

# Get shannon's host key (if you can SSH to it)
ssh-keyscan shannon 2>/dev/null | grep ed25519 | cut -d' ' -f2-

# Get turing's host key (current machine)
cat /etc/ssh/ssh_host_ed25519_key.pub
```

If the machines aren't set up yet, you'll need to:
1. Deploy them first without WireGuard
2. Then get their host keys
3. Then set up the encrypted secrets

## Step 2: Create secrets.nix

Create `secrets/secrets.nix` with the collected keys:

```nix
let
  # Replace these with the actual host keys you collected
  turing = "ssh-ed25519 AAAA... root@turing";
  einstein = "ssh-ed25519 AAAA... root@einstein";
  shannon = "ssh-ed25519 AAAA... root@shannon";
  
  # Your personal key (already have this)
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local";
in
{
  # Each secret specifies which keys can decrypt it
  "wireguard-einstein-private.age".publicKeys = [ user einstein ];
  "wireguard-shannon-private.age".publicKeys = [ user shannon ];
  "wireguard-turing-private.age".publicKeys = [ user turing ];
}
```

## Step 3: Generate WireGuard Keys

```bash
# Generate keys for each host
wg genkey > einstein-private.key
wg genkey > shannon-private.key
wg genkey > turing-private.key

# Generate public keys
cat einstein-private.key | wg pubkey > einstein-public.key
cat shannon-private.key | wg pubkey > shannon-public.key
cat turing-private.key | wg pubkey > turing-public.key
```

## Step 4: Encrypt the Private Keys

```bash
cd /Users/melbournebaldove/.dotfiles/secrets

# Encrypt each private key
agenix -e wireguard-einstein-private.age < einstein-private.key
agenix -e wireguard-shannon-private.age < shannon-private.key
agenix -e wireguard-turing-private.age < turing-private.key

# Delete the plaintext keys
rm *-private.key
```

## Step 5: Update WireGuard Configurations

Replace the placeholders in your WireGuard configs with the PUBLIC keys you generated:
- In `wireguard-server.nix`: Use einstein-public.key and turing-public.key
- In `wireguard-gateway.nix`: Use shannon-public.key

## Step 6: Configure Hosts to Use Agenix Secrets

In each host's WireGuard config, instead of:
```nix
privateKeyFile = "/etc/wireguard/private";
```

Use:
```nix
privateKeyFile = config.age.secrets.wireguard-einstein-private.path;
```

And add the secret declaration:
```nix
age.secrets.wireguard-einstein-private.file = ../secrets/wireguard-einstein-private.age;
```

## Alternative: Start Without Encryption

If this is too complex to start with, you can:
1. First get WireGuard working with manual key management
2. Then add agenix encryption later

Just create the keys manually and place them on each host:
```bash
# On each host
sudo mkdir -p /etc/wireguard
echo "PRIVATE_KEY_HERE" | sudo tee /etc/wireguard/private
sudo chmod 600 /etc/wireguard/private
```