{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/shared/core.nix
    ../../modules/system/shared/ssh-keys.nix
    ../../modules/system/linux/default.nix
    ../../modules/system/linux/agenix.nix
    ../../modules/system/linux/media-server.nix
    ../../modules/system/linux/wireguard-gateway.nix
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

  # Add ntfs-3g for NTFS support
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];

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

  system.stateVersion = "24.05";
}