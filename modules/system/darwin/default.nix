
{
  inputs, ...
}:
{
  imports = [ 
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "melbournebaldove";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "shaunsingh/homebrew-SFMono-Nerd-Font-Ligaturized" = inputs.sf-mono-nerd-font;
    };
    mutableTaps = false;
  };

  users.users.melbournebaldove = {
    name = "melbournebaldove";
    home = "/Users/melbournebaldove"; # This is the standard macOS home path
  };

  # NOTE: These system modifications have been moved to a manual setup script
  # Run setup.sh after initial nix-darwin installation
}
