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

    storage = {
      type = mkOption {
        type = types.enum [ "local" "s3" ];
        default = "local";
        description = "Storage backend type";
      };
      
      dataPath = mkOption {
        type = types.str;
        default = "/var/lib/twenty";
        description = "Base path for Twenty data storage";
      };
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

    email = {
      driver = mkOption {
        type = types.nullOr (types.enum [ "smtp" ]);
        default = null;
        description = "Email driver";
      };

      smtp = {
        host = mkOption {
          type = types.str;
          default = "smtp.gmail.com";
          description = "SMTP host";
        };

        port = mkOption {
          type = types.port;
          default = 587;
          description = "SMTP port";
        };

        secure = mkOption {
          type = types.bool;
          default = true;
          description = "Use TLS/SSL for SMTP";
        };

        user = mkOption {
          type = types.str;
          default = "";
          description = "SMTP username";
        };

        passwordFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing SMTP password";
        };

        from = mkOption {
          type = types.str;
          default = "";
          description = "From email address";
        };
      };
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
        mode = "0400";
      };
      twenty-db-password = {
        file = ../../../secrets/twenty-db-password.age;
        mode = "0400";
      };
      twenty-smtp-password = mkIf (config.services.twenty-crm.email.smtp.passwordFile != null) {
        file = ../../../secrets/twenty-smtp-password.age;
        mode = "0400";
      };
    };

    # Workaround: Ensure worker starts after deployment
    systemd.services.twenty = {
      serviceConfig = {
        # Create runtime directory for environment file
        RuntimeDirectory = "twenty";
        RuntimeDirectoryMode = "0700";
      };
      
      preStart = mkIf (config.services.twenty-crm.database.passwordFile != null || config.services.twenty-crm.appSecretFile != null) ''
        # Read secrets and create environment file
        {
          echo "# Generated environment file for Twenty CRM"
          
          ${optionalString (config.services.twenty-crm.database.passwordFile != null) ''
            DB_PASSWORD=$(cat ${config.services.twenty-crm.database.passwordFile})
            echo "PG_DATABASE_URL=postgres://${config.services.twenty-crm.database.user}:$DB_PASSWORD@db:5432/default"
          ''}
          
          ${optionalString (config.services.twenty-crm.appSecretFile != null) ''
            echo "APP_SECRET=$(cat ${config.services.twenty-crm.appSecretFile})"
          ''}
          
          # Pass through other environment variables  
          echo "REDIS_URL=redis://redis:6379"
          echo "NODE_PORT=${toString config.services.twenty-crm.port}"
          echo "SERVER_URL=${config.services.twenty-crm.serverUrl}"
          echo "STORAGE_TYPE=${config.services.twenty-crm.storage.type}"
          
          # Email configuration
          ${optionalString (config.services.twenty-crm.email.driver == "smtp") ''
            echo "EMAIL_DRIVER=smtp"
            echo "EMAIL_SMTP_HOST=${config.services.twenty-crm.email.smtp.host}"
            echo "EMAIL_SMTP_PORT=${toString config.services.twenty-crm.email.smtp.port}"
            echo "EMAIL_SMTP_USER=${config.services.twenty-crm.email.smtp.user}"
            ${optionalString (config.services.twenty-crm.email.smtp.passwordFile != null) ''
              echo "EMAIL_SMTP_PASSWORD=$(cat ${config.services.twenty-crm.email.smtp.passwordFile})"
            ''}
            echo "EMAIL_FROM_ADDRESS=${config.services.twenty-crm.email.smtp.from}"
            echo "EMAIL_FROM_NAME=Twenty CRM"
          ''}
        } > /run/twenty/env
      '';
      
      postStart = ''
        # Wait for containers to be created
        sleep 10
        # Start the worker if it's not running
        ${pkgs.docker}/bin/docker start twenty-worker-1 || true
      '';
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