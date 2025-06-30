{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./disk-config.nix
    ../../modules/system/shared/core.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "einstein";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
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

  system.stateVersion = "24.05";
}