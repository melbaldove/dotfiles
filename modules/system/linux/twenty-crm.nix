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
        
        callbackUrl = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Google OAuth callback URL";
        };
        
        apisCallbackUrl = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Google APIs callback URL";
        };
      };
      
      microsoft.enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Microsoft authentication";
      };
    };
    
    messagingProviderGmailEnabled = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Gmail messaging provider";
    };
    
    calendarProviderGoogleEnabled = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Google Calendar provider";
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
      twenty-smtp-password = {
        file = ../../../secrets/twenty-smtp-password.age;
        mode = "0400";
      };
      twenty-google-client-id = mkIf config.services.twenty-crm.auth.google.enabled {
        file = ../../../secrets/twenty-google-client-id.age;
        mode = "0400";
      };
      twenty-google-client-secret = mkIf config.services.twenty-crm.auth.google.enabled {
        file = ../../../secrets/twenty-google-client-secret.age;
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
            echo "EMAIL_FROM_NAME=NextDesk"
          ''}
          
          # Google authentication configuration
          ${optionalString config.services.twenty-crm.auth.google.enabled ''
            echo "AUTH_GOOGLE_ENABLED=true"
            ${optionalString (config.services.twenty-crm.auth.google.clientIdFile != null) ''
              echo "AUTH_GOOGLE_CLIENT_ID=$(cat ${config.services.twenty-crm.auth.google.clientIdFile})"
            ''}
            ${optionalString (config.services.twenty-crm.auth.google.clientSecretFile != null) ''
              echo "AUTH_GOOGLE_CLIENT_SECRET=$(cat ${config.services.twenty-crm.auth.google.clientSecretFile})"
            ''}
            ${optionalString (config.services.twenty-crm.auth.google.callbackUrl != null) ''
              echo "AUTH_GOOGLE_CALLBACK_URL=${config.services.twenty-crm.auth.google.callbackUrl}"
            ''}
            ${optionalString (config.services.twenty-crm.auth.google.apisCallbackUrl != null) ''
              echo "AUTH_GOOGLE_APIS_CALLBACK_URL=${config.services.twenty-crm.auth.google.apisCallbackUrl}"
            ''}
          ''}
          
          # Gmail messaging provider
          ${optionalString config.services.twenty-crm.messagingProviderGmailEnabled ''
            echo "MESSAGING_PROVIDER_GMAIL_ENABLED=true"
          ''}
          
          # Google Calendar provider
          ${optionalString config.services.twenty-crm.calendarProviderGoogleEnabled ''
            echo "CALENDAR_PROVIDER_GOOGLE_ENABLED=true"
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

    # Separate service to register Twenty CRM background jobs
    systemd.services.twenty-cron-setup = mkIf (config.services.twenty-crm.messagingProviderGmailEnabled || config.services.twenty-crm.calendarProviderGoogleEnabled) {
      description = "Register Twenty CRM background jobs";
      after = [ "twenty.service" "multi-user.target" ];
      wants = [ "twenty.service" ];
      wantedBy = [ "default.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "300"; # 5 minutes timeout
      };
      
      script = ''
        # Wait for Twenty services to be fully ready
        echo "Waiting for Twenty CRM to be ready..."
        for i in {1..30}; do
          if ${pkgs.docker}/bin/docker exec twenty-server-1 curl -s http://localhost:3000/healthz > /dev/null 2>&1; then
            echo "Twenty CRM is ready, registering cron jobs..."
            break
          fi
          echo "Attempt $i/30: Twenty CRM not ready yet, waiting..."
          sleep 10
        done
        
        # Register messaging cron jobs
        ${optionalString config.services.twenty-crm.messagingProviderGmailEnabled ''
          echo "Registering messaging cron jobs..."
          ${pkgs.docker}/bin/docker exec twenty-server-1 yarn command:prod cron:messaging:messages-import || echo "Failed to register messages-import job"
          ${pkgs.docker}/bin/docker exec twenty-server-1 yarn command:prod cron:messaging:message-list-fetch || echo "Failed to register message-list-fetch job"
          ${pkgs.docker}/bin/docker exec twenty-server-1 yarn command:prod cron:messaging:ongoing-stale || echo "Failed to register messaging ongoing-stale job"
        ''}
        
        # Register calendar cron jobs
        ${optionalString config.services.twenty-crm.calendarProviderGoogleEnabled ''
          echo "Registering calendar cron jobs..."
          ${pkgs.docker}/bin/docker exec twenty-server-1 yarn command:prod cron:calendar:calendar-event-list-fetch || echo "Failed to register calendar-event-list-fetch job"
          ${pkgs.docker}/bin/docker exec twenty-server-1 yarn command:prod cron:calendar:calendar-events-import || echo "Failed to register calendar-events-import job"
          ${pkgs.docker}/bin/docker exec twenty-server-1 yarn command:prod cron:calendar:ongoing-stale || echo "Failed to register calendar ongoing-stale job"
        ''}
        
        # Register workflow cron trigger (always enabled when integrations are active)
        echo "Registering workflow cron trigger..."
        ${pkgs.docker}/bin/docker exec twenty-server-1 yarn command:prod cron:workflow:automated-cron-trigger || echo "Failed to register workflow cron trigger"
        
        echo "Cron job registration completed"
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