{ config, lib, pkgs, ... }:

{
  # WireGuard tools from Homebrew
  homebrew.brews = [ "wireguard-tools" ];

  # Command-line tools from Nix (backup)
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}