{ config, lib, pkgs, inputs, ... }:

with lib;

{
  options.services.outline-wiki = {
    enable = mkEnableOption "Outline Wiki";

    url = mkOption {
      type = types.str;
      default = "http://localhost:3001";
      description = "Public URL of the Outline instance";
    };

    port = mkOption {
      type = types.port;
      default = 3001;
      description = "Port to expose Outline on";
    };

    secretKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing secret key";
    };

    utilsSecretFile = mkOption {
      type = types.path;
      description = "Path to file containing utils secret";
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
        default = "outline";
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

    auth = {
      google = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Google authentication";
        };

        clientIdFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing Google OAuth client ID";
        };

        clientSecretFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to file containing Google OAuth client secret";
        };
      };
    };

    smtp = {
      enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable SMTP email";
      };

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

      fromEmail = mkOption {
        type = types.str;
        default = "";
        description = "From email address";
      };

      replyEmail = mkOption {
        type = types.str;
        default = "";
        description = "Reply-to email address";
      };
    };

    slack = {
      enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Slack integration";
      };

      appId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Slack App ID";
      };

      messageActions = mkOption {
        type = types.bool;
        default = false;
        description = "Enable 'Post to Channel' button in search results";
      };
    };
  };

  config = mkIf config.services.outline-wiki.enable {
    # Enable container runtime for Arion
    virtualisation.docker.enable = true;
    virtualisation.podman.enable = false;
    
    # Configure Arion backend
    virtualisation.arion.backend = "docker";
    
    # Add user to docker group
    users.users.melbournebaldove.extraGroups = [ "docker" ];

    # Configure Outline secrets
    age.secrets = {
      outline-secret-key = {
        file = ../../../secrets/outline-secret-key.age;
        mode = "0400";
      };
      outline-utils-secret = {
        file = ../../../secrets/outline-utils-secret.age;
        mode = "0400";
      };
      outline-db-password = {
        file = ../../../secrets/outline-db-password.age;
        mode = "0400";
      };
      outline-smtp-password = mkIf config.services.outline-wiki.smtp.enabled {
        file = ../../../secrets/outline-smtp-password.age;
        mode = "0400";
      };
      outline-google-client-id = mkIf config.services.outline-wiki.auth.google.enabled {
        file = ../../../secrets/outline-google-client-id.age;
        mode = "0400";
      };
      outline-google-client-secret = mkIf config.services.outline-wiki.auth.google.enabled {
        file = ../../../secrets/outline-google-client-secret.age;
        mode = "0400";
      };
      outline-linear-client-id = {
        file = ../../../secrets/outline-linear-client-id.age;
        mode = "0400";
      };
      outline-linear-client-secret = {
        file = ../../../secrets/outline-linear-client-secret.age;
        mode = "0400";
      };
      outline-slack-client-id = mkIf config.services.outline-wiki.slack.enabled {
        file = ../../../secrets/outline-slack-client-id.age;
        mode = "0400";
      };
      outline-slack-client-secret = mkIf config.services.outline-wiki.slack.enabled {
        file = ../../../secrets/outline-slack-client-secret.age;
        mode = "0400";
      };
      outline-slack-verification-token = mkIf config.services.outline-wiki.slack.enabled {
        file = ../../../secrets/outline-slack-verification-token.age;
        mode = "0400";
      };
    };

    # Configure Outline service with secrets handling
    systemd.services.outline = {
      serviceConfig = {
        # Create runtime directory for environment file
        RuntimeDirectory = "outline";
        RuntimeDirectoryMode = "0700";
      };
      
      preStart = ''
        # Read secrets and create environment file
        {
          echo "# Generated environment file for Outline"
          
          # Database URL with password from file
          DB_PASSWORD=$(cat ${config.services.outline-wiki.database.passwordFile})
          echo "DATABASE_URL=postgres://${config.services.outline-wiki.database.user}:$DB_PASSWORD@${config.services.outline-wiki.database.host}:${toString config.services.outline-wiki.database.port}/${config.services.outline-wiki.database.database}?sslmode=disable"
          
          # Disable SSL for database connection
          echo 'DATABASE_SSL=false'
          
          # Secret keys
          echo "SECRET_KEY=$(cat ${config.services.outline-wiki.secretKeyFile})"
          echo "UTILS_SECRET=$(cat ${config.services.outline-wiki.utilsSecretFile})"
          
          # Google OAuth if enabled
          ${optionalString config.services.outline-wiki.auth.google.enabled ''
            echo "GOOGLE_CLIENT_ID=$(cat ${config.services.outline-wiki.auth.google.clientIdFile})"
            echo "GOOGLE_CLIENT_SECRET=$(cat ${config.services.outline-wiki.auth.google.clientSecretFile})"
          ''}
          
          # Linear OAuth
          echo "LINEAR_CLIENT_ID=$(cat ${config.age.secrets.outline-linear-client-id.path})"
          echo "LINEAR_CLIENT_SECRET=$(cat ${config.age.secrets.outline-linear-client-secret.path})"
          
          # Slack OAuth if enabled
          ${optionalString config.services.outline-wiki.slack.enabled ''
            echo "SLACK_CLIENT_ID=$(cat ${config.age.secrets.outline-slack-client-id.path})"
            echo "SLACK_CLIENT_SECRET=$(cat ${config.age.secrets.outline-slack-client-secret.path})"
            echo "SLACK_VERIFICATION_TOKEN=$(cat ${config.age.secrets.outline-slack-verification-token.path})"
          ''}
          
          # SMTP configuration if enabled
          ${optionalString config.services.outline-wiki.smtp.enabled ''
            ${optionalString (config.services.outline-wiki.smtp.passwordFile != null) ''
              echo "SMTP_PASSWORD=$(cat ${config.services.outline-wiki.smtp.passwordFile})"
            ''}
          ''}
        } > /run/outline/env
      '';
      
      postStart = ''
        # Wait for containers to be ready
        echo "Waiting for Outline container to be ready..."
        for i in {1..30}; do
          if ${pkgs.docker}/bin/docker ps | grep outline-outline-1 | grep -q "Up"; then
            echo "Outline container is running, running database setup..."
            break
          fi
          echo "Attempt $i/30: Outline container not ready yet, waiting..."
          sleep 5
        done
        
        # Run database migrations (idempotent operation)
        echo "Running database migrations..."
        ${pkgs.docker}/bin/docker exec outline-outline-1 yarn db:migrate || echo "Migration failed or already applied"
        
        echo "Outline post-deployment setup completed"
      '';
    };

    # Configure Arion project for Outline
    virtualisation.arion.projects.outline = {
      serviceName = "outline";
      settings = {
        imports = [ 
          (import "${inputs.outline}/arion-compose.nix" {
            inherit pkgs lib;
            config = config.services.outline-wiki;
          })
        ];
      };
    };
  };
}