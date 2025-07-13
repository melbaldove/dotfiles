{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/shared/core.nix
    ../../modules/system/shared/ssh-keys.nix
    ../../modules/system/shared/promtail.nix
    ../../modules/system/linux/default.nix
    ../../modules/system/linux/agenix.nix
    ../../modules/system/linux/media-server.nix
    ../../modules/system/linux/wireguard-gateway.nix
    ../../modules/system/shared/node-exporter.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "einstein";
  networking.extraHosts = ''
    172.236.148.68 shannon
    157.180.91.120 newton
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Mount /dev/sda1 to /mnt/media (NTFS)
  fileSystems."/mnt/media" = {
    device = "/dev/sda1";
    fsType = "ntfs-3g";
    options = [ "defaults" "rw" "uid=1000" "gid=100" "umask=002" "nofail" ];
  };

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };

  # Backup storage validation
  assertions = [
    {
      assertion = config.fileSystems."/mnt/media".device != null;
      message = "Media mount required for backup storage at /mnt/media";
    }
  ];

  # Add ntfs-3g for NTFS support
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];

  # Backup repository configuration
  users.users.backup = {
    isSystemUser = true;
    group = "backup";
    home = "/var/lib/backup";
    createHome = true;
    extraGroups = [ "users" ];  # Add to users group for NTFS access
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnMg5Par0DrgIG8UAWFi+YD4aJgCHGZK8zWy8OlBHlK newton-backup"
    ];
  };

  users.groups.backup = {};

  # Create backup directory with validation
  systemd.tmpfiles.rules = [
    "d /mnt/media/backups 0750 backup backup -"
    "d /mnt/media/backups/newton-restic 0750 backup backup -"
  ];

  # Validate backup storage is accessible
  systemd.services.backup-storage-check = {
    description = "Validate backup storage accessibility";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "backup-storage-check" ''
        if [[ ! -d /mnt/media ]]; then
          echo "ERROR: /mnt/media is not mounted"
          exit 1
        fi
        if [[ ! -w /mnt/media ]]; then
          echo "ERROR: /mnt/media is not writable"
          exit 1
        fi
        echo "Backup storage validation successful"
      '';
    };
  };

  # Configure as remote builder
  nix.settings = {
    trusted-users = [ "root" "melbournebaldove" ];
  };


  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = {
      imports = [
        ../../users/melbournebaldove/core.nix
        ../../users/melbournebaldove/claude.nix
        ../../users/melbournebaldove/dev.nix
      ];
    };
  };

  monitoring.nodeExporter.listenAddress = "10.0.0.2";

  # Allow promtail port on VPN interface
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9080 ];

  system.stateVersion = "24.05";
}