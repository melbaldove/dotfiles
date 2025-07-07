let
  # SSH public keys for each host
  turing = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local";
  einstein = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbSfyESdV7Wr9zSHDbjLt2+/Fql3uEOEdxjhHvDDdmc";
  shannon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS8buEp8SU2tKN/4ZNA8PLNiyJRKHwPoG1THgFx3lzT";
  newton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJfIq1FgAcBRgqEom/w/WEIfBc81+CTUfdsAWvqZ72FU";

  # User keys (for managing secrets)
  user = turing; # Use turing's key for secret management
in
{
  # WireGuard private keys - each machine can only decrypt its own key
  "wireguard-einstein-private.age".publicKeys = [ user einstein ];
  "wireguard-shannon-private.age".publicKeys = [ user shannon ];
  "wireguard-shannon-startup-private.age".publicKeys = [ user shannon ];
  "wireguard-turing-private.age".publicKeys = [ user turing ];
  "wireguard-newton-private.age".publicKeys = [ user newton ];

  # Twenty CRM secrets
  "twenty-app-secret.age".publicKeys = [ user newton ];
  "twenty-db-password.age".publicKeys = [ user newton ];

  # Ghost CMS secrets
  "ghost-db-password.age".publicKeys = [ user newton ];
  "ghost-smtp-password.age".publicKeys = [ user newton ];

  # Twenty CRM SMTP secrets
  "twenty-smtp-password.age".publicKeys = [ user newton ];
  
  # Twenty CRM Google OAuth secrets
  "twenty-google-client-id.age".publicKeys = [ user newton ];
  "twenty-google-client-secret.age".publicKeys = [ user newton ];
}