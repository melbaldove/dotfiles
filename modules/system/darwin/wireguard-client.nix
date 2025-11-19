{ config, lib, pkgs, ... }:

{
  # Disable Homebrew formulae; rely solely on Nix packages.
  homebrew.brews = lib.mkForce [ ];

  # Command-line tools from Nix
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}
