{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/shared/core.nix
    ../../modules/system/shared/ssh-keys.nix
    ../../modules/system/linux/default.nix
    ../../modules/system/linux/wireguard-server.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "shannon";
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false; # Disable DHCP globally as we will not need it.
  # required for ssh?
  networking.interfaces.eth0.useDHCP = true;

  boot.loader.grub.enable = true;

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" "networkmanager" ];
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