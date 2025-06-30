{ config, lib, pkgs, ... }:

{
  # Jellyfin media server (open-source alternative to Emby/Plex)
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/var/lib/jellyfin";
    configDir = "/var/lib/jellyfin/config";
    cacheDir = "/var/cache/jellyfin";
    logDir = "/var/log/jellyfin";
    user = "jellyfin";
    group = "jellyfin";
  };

  # Create jellyfin user and ensure media directory permissions
  users.users.jellyfin = {
    isSystemUser = true;
    group = "jellyfin";
    extraGroups = [ "video" "audio" "users" ];
  };
  users.groups.jellyfin = {};

  # Ensure media mount is accessible to jellyfin
  systemd.tmpfiles.rules = [
    "d /mnt/media 0755 root users -"
    "Z /mnt/media 0755 root users -"
  ];

  # Open firewall ports for Jellyfin
  networking.firewall = {
    allowedTCPPorts = [ 
      8096  # HTTP web interface
      8920  # HTTPS web interface  
    ];
    allowedUDPPorts = [
      1900  # DLNA discovery
      7359  # Jellyfin autodiscovery
    ];
  };
}