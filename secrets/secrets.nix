let
  # SSH public keys for each host
  turing = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local";
  einstein = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbSfyESdV7Wr9zSHDbjLt2+/Fql3uEOEdxjhHvDDdmc";
  shannon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS8buEp8SU2tKN/4ZNA8PLNiyJRKHwPoG1THgFx3lzT";

  # User keys (for managing secrets)
  user = turing; # Use turing's key for secret management
in
{
  # WireGuard private keys - each machine can only decrypt its own key
  "wireguard-einstein-private.age".publicKeys = [ user einstein ];
  "wireguard-shannon-private.age".publicKeys = [ user shannon ];
  "wireguard-turing-private.age".publicKeys = [ user turing ];
}