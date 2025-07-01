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
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Mount /dev/sda1 to /mnt/media
  fileSystems."/mnt/media" = {
    device = "/dev/sda1";
    fsType = "auto";
    options = [ "defaults" "user" "rw" ];
  };

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };


  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = {
      imports = [
        ../../users/melbournebaldove/core.nix
        ../../users/melbournebaldove/claude.nix
      ];
    };
  };

  system.stateVersion = "24.05";
}