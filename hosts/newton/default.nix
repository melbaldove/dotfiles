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
    ../../modules/system/linux/ghost-cms.nix
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
      passwordFile = config.age.secrets.twenty-db-password.path;
    };
    
    appSecretFile = config.age.secrets.twenty-app-secret.path;
    
    storage = {
      type = "local";
      dataPath = "/mnt/data";
    };
    auth.google.enabled = false;
    auth.microsoft.enabled = false;
    email.driver = null;
  };

  # Configure Ghost CMS service
  services.ghost-cms = {
    enable = true;
    url = "https://blog.workwithnextdesk.com";
    port = 8080;
    
    database = {
      client = "mysql";
      host = "db";
      user = "root";
      database = "ghost";
      passwordFile = config.age.secrets.ghost-db-password.path;
    };
    
    mail = {
      transport = "Direct";
      from = null;
    };
    
    nodeEnv = "production";
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