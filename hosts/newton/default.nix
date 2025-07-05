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
    ../../modules/system/shared/node-exporter.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "newton";
  networking.extraHosts = ''
    172.236.148.68 shannon
  '';

  # WireGuard VPN client configuration
  age.secrets.wireguard-newton-private.file = ../../secrets/wireguard-newton-private.age;

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.1.2/24" ];
      privateKeyFile = config.age.secrets.wireguard-newton-private.path;

      peers = [
        {
          # Shannon VPN server (startup interface)
          publicKey = "VyeqpVLFr+62pyzKUI4Dq/WZXS5pZR/Ps2Yx3aNKgm0=";
          allowedIPs = [ "10.0.1.0/24" ];
          endpoint = "shannon:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  # Node exporter configuration
  monitoring.nodeExporter.listenAddress = "10.0.1.2";

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
    url = "https://cms.workwithnextdesk.com";
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