
{
  inputs, lib, ...
}:
let
  # Import network host mappings
  networkHosts = import ../../../network/hosts.nix;
  
  # Generate /etc/hosts entries from network mappings
  hostsEntries = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (hostname: ip: "${ip} ${hostname}") networkHosts
  );
in
{
  imports = [ 
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  # Network configuration - add entries to /etc/hosts
  environment.etc."hosts".text = ''
    ##
    # Host Database
    #
    # localhost is used to configure the loopback interface
    # when the system is booting.  Do not change this entry.
    ##
    127.0.0.1	localhost
    255.255.255.255	broadcasthost
    ::1             localhost

    # Custom host mappings
    ${hostsEntries}
  '';

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
