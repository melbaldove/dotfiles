{
  description = "Main config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    sf-mono-nerd-font = {
      url = "github:shaunsingh/SFMono-Nerd-Font-Ligaturized";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nix-homebrew, nixpkgs, ... }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Turing
    darwinConfigurations."Turing" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs self; };
      modules = [ 
        ./configuration.nix
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.melbournebaldove = import ./home.nix;
        }
        nix-homebrew.darwinModules.nix-homebrew
        {
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
        }
      ];
    };
  };
}
