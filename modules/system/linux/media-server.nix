{ config, lib, pkgs, ... }:

{
  # Emby media server
  services.emby = {
    enable = true;
    openFirewall = true;
    dataDir = "/var/lib/emby";
    user = "emby";
    group = "emby";
  };

  # Create emby user and ensure media directory permissions
  users.users.emby = {
    isSystemUser = true;
    group = "emby";
    extraGroups = [ "video" "audio" ];
  };
  users.groups.emby = {};

  # Ensure media mount is accessible to emby
  systemd.tmpfiles.rules = [
    "d /mnt/media 0755 root users -"
    "Z /mnt/media 0755 root users -"
  ];

  # Open firewall ports for Emby
  networking.firewall = {
    allowedTCPPorts = [ 
      8096  # HTTP web interface
      8920  # HTTPS web interface  
    ];
    allowedUDPPorts = [
      1900  # DLNA discovery
      7359  # Emby autodiscovery
    ];
  };
}