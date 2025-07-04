{ config, lib, pkgs, inputs, ... }:

with lib;

{
  imports = [
    (builtins.fetchTarball {
      url = "https://github.com/hercules-ci/arion/archive/4f59059633b14364b994503b179a701f5e6cfb90.tar.gz";
      sha256 = "0sz98yxm9f42zf2ar2sid2x06gvv21bjybndb1ng9qil9gqxaw9s";
    } + "/nixos-module.nix")
  ];

  options.services.twenty-crm = {
    enable = mkEnableOption "Twenty CRM";

    serverUrl = mkOption {
      type = types.str;
      default = "http://localhost:3000";
      description = "Public URL of the Twenty instance";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port to expose Twenty on";
    };

    appSecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing app secret";
    };

    database = {
      user = mkOption {
        type = types.str;
        default = "postgres";
        description = "PostgreSQL user";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing PostgreSQL password";
      };
    };

    storage.type = mkOption {
      type = types.enum [ "local" "s3" ];
      default = "local";
      description = "Storage backend type";
    };

    auth = {
      google.enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Google authentication";
      };
      microsoft.enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Microsoft authentication";
      };
    };

    email.driver = mkOption {
      type = types.nullOr (types.enum [ "smtp" ]);
      default = null;
      description = "Email driver";
    };
  };

  config = mkIf config.services.twenty-crm.enable {
    # Enable container runtime for Arion
    virtualisation.docker.enable = true;
    virtualisation.podman.enable = false;
    
    # Configure Arion backend
    virtualisation.arion.backend = "docker";
    
    # Add user to docker group
    users.users.melbournebaldove.extraGroups = [ "docker" ];

    # Configure Twenty CRM secrets
    age.secrets = {
      twenty-app-secret = {
        file = ../../../secrets/twenty-app-secret.age;
        mode = "0444";
      };
      twenty-db-password = {
        file = ../../../secrets/twenty-db-password.age;
        mode = "0444";
      };
    };

    # Configure Arion project for Twenty CRM
    virtualisation.arion.projects.twenty = {
      serviceName = "twenty";
      settings = {
        imports = [ 
          (import "${inputs.twenty}/arion-compose.nix" {
            inherit pkgs lib;
            config = config.services.twenty-crm;
          })
        ];
      };
    };
  };
}