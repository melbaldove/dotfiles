
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
    home = "/Users/melbournebaldove";
  };

  system.activationScripts.extraActivation.text =
    ''
      xcode-select --install || true
      softwareupdate --install-rosetta --agree-to-license
    '';
}
