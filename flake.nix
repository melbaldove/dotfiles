
{
  description = "Melbourne's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    twenty.url = "github:next-desk-business-solutions/twenty";
    ghost.url = "github:next-desk-business-solutions/Ghost";
    outline.url = "github:next-desk-business-solutions/outline";

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";

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

  outputs = inputs@{ self, nix-darwin, home-manager, nix-homebrew, nixpkgs, deploy-rs, ... }:
  {
    darwinConfigurations."turing" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs self; };
      modules = [ 
        ./hosts/turing/default.nix
      ];
    };

    nixosConfigurations."einstein" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [ 
        ./hosts/einstein/default.nix
      ];
    };

    nixosConfigurations."shannon" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [ 
        ./hosts/shannon/default.nix
      ];
    };

    nixosConfigurations."newton" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [ 
        ./hosts/newton/default.nix
      ];
    };

    deploy.nodes.einstein = {
      hostname = "einstein";
      remoteBuild = true;
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos 
          self.nixosConfigurations.einstein;
      };
    };

    deploy.nodes.shannon = {
      hostname = "shannon";
      remoteBuild = true;
      magicRollback = false;
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos 
          self.nixosConfigurations.shannon;
      };
    };

    deploy.nodes.newton = {
      hostname = "newton";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos 
          self.nixosConfigurations.newton;
      };
    };

    checks = builtins.mapAttrs 
      (system: deployLib: deployLib.deployChecks self.deploy) 
      deploy-rs.lib;
  };
}
