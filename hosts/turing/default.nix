
{
  inputs, pkgs, ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../../modules/system/darwin/default.nix
    ../../modules/system/darwin/gui.nix
    ../../modules/system/darwin/agenix.nix
    ../../modules/system/darwin/wireguard-client.nix
    ../../modules/system/shared/core.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; self = inputs.self; };
    users.melbournebaldove = {
      imports = [
        ../../users/melbournebaldove/core.nix
        ../../users/melbournebaldove/dev.nix
        ../../users/melbournebaldove/desktop.nix
        ../../users/melbournebaldove/emacs.nix
      ];
    };
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set the hostname
  networking.hostName = "turing";

  # Enable TouchID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Turing-specific packages
  environment.systemPackages = with pkgs; [
    wakeonlan
  ];

  nix.enable = false;
}
