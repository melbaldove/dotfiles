{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nginx.nix
    ../../modules/system/shared/core.nix
    ../../modules/system/shared/ssh-keys.nix
    ../../modules/system/linux/default.nix
    ../../modules/system/linux/agenix.nix
    ../../modules/system/linux/twenty-crm.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "newton";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Mount /dev/sdb to /mnt/data
  fileSystems."/mnt/data" = {
    device = "/dev/sdb";
    fsType = "ext4";
    options = [ "defaults" "rw" ];
  };

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    arion
    docker-compose
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };

  # Configure Twenty CRM service
  services.twenty-crm = {
    enable = true;
    serverUrl = "https://crm.workwithnextdesk.com";
    port = 3000;
    
    database = {
      user = "postgres";
    };
    
    storage.type = "local";
    auth.google.enabled = false;
    auth.microsoft.enabled = false;
    email.driver = null;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = {
      imports = [
        ../../users/melbournebaldove/core.nix
      ];
    };
  };

  system.stateVersion = "24.11";
}