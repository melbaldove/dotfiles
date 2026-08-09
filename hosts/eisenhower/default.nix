{ inputs, pkgs, ... }:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../../modules/system/darwin/default.nix
    ../../modules/system/darwin/gui.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      self = inputs.self;
    };
    users.melbournebaldove.imports = [
      ../../users/melbournebaldove/core.nix
      ../../users/melbournebaldove/dev.nix
      ../../users/melbournebaldove/desktop.nix
      ../../users/melbournebaldove/emacs.nix
    ];
  };

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 6;
  system.primaryUser = "melbournebaldove";

  nixpkgs = {
    hostPlatform.system = "aarch64-darwin";
    config.allowUnfree = true;
  };

  networking.hostName = "eisenhower";
  security.pam.services.sudo_local.touchIdAuth = true;

  environment.systemPackages = with pkgs; [
    vim
    coreutils
    findutils
    jq
    tmux
    curl
    wget
  ];

  environment.variables.PUPPETEER_EXECUTABLE_PATH =
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

  nix.enable = false;
}
