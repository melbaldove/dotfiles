{ config, lib, pkgs, inputs, ... }:

with lib;

{
  options.services.n8n = {
    enable = mkEnableOption "n8n workflow automation";

    url = mkOption {
      type = types.str;
      default = "https://n8n.workwithnextdesk.com";
      description = "Public URL of the n8n instance";
    };

    port = mkOption {
      type = types.port;
      default = 5678;
      description = "Port to expose n8n on";
    };

    encryptionKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing n8n encryption key";
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "twenty-db-1";
        description = "Database host (reusing Twenty's PostgreSQL)";
      };

      port = mkOption {
        type = types.port;
        default = 5432;
        description = "Database port";
      };

      user = mkOption {
        type = types.str;
        default = "postgres";
        description = "Database user";
      };

      passwordFile = mkOption {
        type = types.path;
        description = "Path to file containing database password";
      };

      database = mkOption {
        type = types.str;
        default = "n8n";
        description = "Database name";
      };
    };

    redis = {
      host = mkOption {
        type = types.str;
        default = "twenty-redis-1";
        description = "Redis host (reusing Twenty's Redis)";
      };

      port = mkOption {
        type = types.port;
        default = 6379;
        description = "Redis port";
      };
    };

    basicAuth = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable basic authentication";
      };

      user = mkOption {
        type = types.str;
        default = "admin";
        description = "Basic auth username";
      };

      passwordFile = mkOption {
        type = types.path;
        description = "Path to file containing basic auth password";
      };
    };

  };

  config = mkIf config.services.n8n.enable {
    # Enable container runtime for Arion
    virtualisation.docker.enable = true;
    virtualisation.podman.enable = false;
    
    # Configure Arion backend
    virtualisation.arion.backend = "docker";
    
    # Add user to docker group
    users.users.melbournebaldove.extraGroups = [ "docker" ];

    # Configure n8n secrets
    age.secrets = {
      n8n-encryption-key = {
        file = ../../../secrets/n8n-encryption-key.age;
        mode = "0400";
      };
      n8n-db-password = {
        file = ../../../secrets/n8n-db-password.age;
        mode = "0400";
      };
      n8n-basic-auth-password = {
        file = ../../../secrets/n8n-basic-auth-password.age;
        mode = "0400";
      };
    };

    # Configure n8n service with secrets handling
    systemd.services.n8n = {
      serviceConfig = {
        # Create runtime directory for environment file
        RuntimeDirectory = "n8n";
        RuntimeDirectoryMode = "0700";
      };
      
      preStart = ''
        # Read secrets and create environment file
        {
          echo "# Generated environment file for n8n"
          
          # Database URL with password from file
          DB_PASSWORD=$(cat ${config.services.n8n.database.passwordFile})
          echo "DB_POSTGRESDB_PASSWORD=$DB_PASSWORD"
          
          # Encryption key
          echo "N8N_ENCRYPTION_KEY=$(cat ${config.services.n8n.encryptionKeyFile})"
          
          # Basic auth password
          echo "N8N_BASIC_AUTH_PASSWORD=$(cat ${config.services.n8n.basicAuth.passwordFile})"
          
        } > /run/n8n/env
      '';
      
      postStart = ''
        # Wait for containers to be ready
        echo "Waiting for n8n container to be ready..."
        for i in {1..30}; do
          if ${pkgs.docker}/bin/docker ps | grep n8n-n8n-1 | grep -q "Up"; then
            echo "n8n container is running"
            break
          fi
          echo "Attempt $i/30: n8n container not ready yet, waiting..."
          sleep 5
        done
        
        echo "n8n post-deployment setup completed"
      '';
    };

    # Configure Arion project for n8n
    virtualisation.arion.projects.n8n = {
      serviceName = "n8n";
      settings = {
        imports = [ 
          (import "${inputs.pulse}/arion-compose.nix" {
            inherit pkgs lib;
            config = config.services.n8n // {
              pulseProjectPath = "${inputs.pulse}";
            };
          })
        ];
      };
    };
  };
}