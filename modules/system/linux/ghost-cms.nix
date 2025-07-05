{ config, lib, pkgs, inputs, ... }:

with lib;

{
  imports = [
    (builtins.fetchTarball {
      url = "https://github.com/hercules-ci/arion/archive/4f59059633b14364b994503b179a701f5e6cfb90.tar.gz";
      sha256 = "0sz98yxm9f42zf2ar2sid2x06gvv21bjybndb1ng9qil9gqxaw9s";
    } + "/nixos-module.nix")
  ];

  options.services.ghost-cms = {
    enable = mkEnableOption "Ghost CMS";

    url = mkOption {
      type = types.str;
      default = "http://localhost:8080";
      description = "Public URL of the Ghost instance";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to expose Ghost on";
    };

    database = {
      client = mkOption {
        type = types.enum [ "mysql" "sqlite3" ];
        default = "mysql";
        description = "Database client type";
      };

      host = mkOption {
        type = types.str;
        default = "db";
        description = "Database host";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "Database user";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing database password";
      };

      database = mkOption {
        type = types.str;
        default = "ghost";
        description = "Database name";
      };
    };

    mail = {
      transport = mkOption {
        type = types.nullOr types.str;
        default = "Direct";
        description = "Mail transport method";
      };

      from = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "From email address";
      };

      smtp = {
        host = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "SMTP host";
        };

        port = mkOption {
          type = types.nullOr types.port;
          default = null;
          description = "SMTP port";
        };

        secure = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Use secure SMTP connection";
        };

        userFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing SMTP username";
        };

        passwordFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing SMTP password";
        };
      };
    };

    nodeEnv = mkOption {
      type = types.enum [ "production" "development" ];
      default = "production";
      description = "Node environment";
    };

    contentPath = mkOption {
      type = types.str;
      default = "/var/lib/ghost/content";
      description = "Path to Ghost content directory";
    };
  };

  config = mkIf config.services.ghost-cms.enable {
    # Enable container runtime for Arion
    virtualisation.docker.enable = true;
    virtualisation.podman.enable = false;
    
    # Configure Arion backend
    virtualisation.arion.backend = "docker";
    
    # Add user to docker group
    users.users.melbournebaldove.extraGroups = [ "docker" ];

    # Configure Ghost CMS secrets
    age.secrets = {
      ghost-db-password = {
        file = ../../../secrets/ghost-db-password.age;
        mode = "0444";
      };
    } // lib.optionalAttrs (config.services.ghost-cms.mail.smtp.userFile != null) {
      ghost-smtp-user = {
        file = ../../../secrets/ghost-smtp-user.age;
        mode = "0444";
      };
    } // lib.optionalAttrs (config.services.ghost-cms.mail.smtp.passwordFile != null) {
      ghost-smtp-password = {
        file = ../../../secrets/ghost-smtp-password.age;
        mode = "0444";
      };
    };

    # Configure Arion project for Ghost CMS
    virtualisation.arion.projects.ghost = {
      serviceName = "ghost";
      settings = {
        imports = [ 
          (import "${inputs.ghost}/ghost-arion-compose.nix" {
            inherit pkgs lib;
            config = config.services.ghost-cms;
          })
        ];
      };
    };
  };
}