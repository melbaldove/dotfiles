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

        user = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "SMTP username";
        };

        password = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "SMTP password";
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
        mode = "0400";
      };
      ghost-smtp-password = {
        file = ../../../secrets/ghost-smtp-password.age;
        mode = "0400";
      };
    };

    # Configure Ghost CMS service with secrets handling
    systemd.services.ghost = {
      serviceConfig = {
        # Create runtime directory for environment file
        RuntimeDirectory = "ghost";
        RuntimeDirectoryMode = "0700";
      };
      
      preStart = mkIf (config.services.ghost-cms.database.passwordFile != null || config.services.ghost-cms.mail.smtp.passwordFile != null || config.services.ghost-cms.mail.smtp.userFile != null) ''
        # Read secrets and create environment file
        {
          echo "# Generated environment file for Ghost CMS"
          
          ${optionalString (config.services.ghost-cms.database.passwordFile != null) ''
            DB_PASSWORD=$(cat ${config.services.ghost-cms.database.passwordFile})
            echo "database__connection__password=$DB_PASSWORD"
          ''}
          
          ${optionalString (config.services.ghost-cms.mail.smtp.userFile != null) ''
            echo "mail__options__auth__user=$(cat ${config.services.ghost-cms.mail.smtp.userFile})"
          ''}
          
          ${optionalString (config.services.ghost-cms.mail.smtp.passwordFile != null) ''
            echo "mail__options__auth__pass=$(cat ${config.services.ghost-cms.mail.smtp.passwordFile})"
          ''}
        } > /run/ghost/env
      '';
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