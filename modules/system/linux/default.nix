{ pkgs, ... }:
{

  # Set time zone
  time.timeZone = "Asia/Manila";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure sudo
  security.sudo.wheelNeedsPassword = false;

  # Enable SSH for Linux systems
  services.openssh.enable = true;

  # Open SSH port in firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Linux-specific packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    tmux
  ];
}
