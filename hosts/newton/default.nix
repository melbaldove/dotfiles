{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nginx.nix
    ../../modules/system/shared/core.nix
    ../../modules/system/shared/ssh-keys.nix
    ../../modules/system/shared/promtail.nix
    ../../modules/system/linux/default.nix
    ../../modules/system/linux/agenix.nix
    ../../modules/system/linux/twenty-crm.nix
    ../../modules/system/linux/ghost-cms.nix
    ../../modules/system/linux/outline.nix
    ../../modules/system/shared/node-exporter.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "newton";
  networking.extraHosts = ''
    172.236.148.68 shannon
  '';

  # WireGuard VPN client configuration
  age.secrets.wireguard-newton-private.file = ../../secrets/wireguard-newton-private.age;

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.1.2/24" ];
      privateKeyFile = config.age.secrets.wireguard-newton-private.path;

      peers = [
        {
          # Shannon VPN server (startup interface)
          publicKey = "VyeqpVLFr+62pyzKUI4Dq/WZXS5pZR/Ps2Yx3aNKgm0=";
          allowedIPs = [ "10.0.1.0/24" ];
          endpoint = "shannon:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  # Node exporter configuration
  monitoring.nodeExporter.listenAddress = "10.0.1.2";

  # cAdvisor for Docker container metrics
  services.cadvisor = {
    enable = true;
    port = 9200;
    listenAddress = "10.0.1.2";
  };

  # Allow VPN traffic to monitoring ports
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9100 9200 9080 ];

  # Override Promtail client to use Shannon's startup network IP
  services.promtail.configuration.clients = lib.mkForce [
    {
      url = "http://10.0.1.1:3100/loki/api/v1/push";
    }
  ];

  # Newton-specific Promtail configuration for Docker logs
  services.promtail.configuration.scrape_configs = lib.mkAfter [
    {
      job_name = "docker-containers";
      docker_sd_configs = [
        {
          host = "unix:///var/run/docker.sock";
          refresh_interval = "5s";
          # Collect logs from all containers, not just those with specific labels
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__meta_docker_container_name" ];
          regex = "/(.*)";
          target_label = "container";
          replacement = "\${1}";
        }
        {
          source_labels = [ "__meta_docker_container_log_stream" ];
          target_label = "stream";
        }
        {
          source_labels = [ "__meta_docker_container_label_com_docker_compose_service" ];
          target_label = "compose_service";
        }
        {
          source_labels = [ "__meta_docker_container_label_com_docker_compose_project" ];
          target_label = "compose_project";
        }
        {
          source_labels = [ "__meta_docker_container_image" ];
          target_label = "image";
        }
      ];
      pipeline_stages = [
        {
          docker = {};
        }
        {
          timestamp = {
            source = "timestamp";
            format = "RFC3339Nano";
          };
        }
      ];
    }
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";


  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    arion
    docker-compose
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };

  # Grant promtail access to Docker socket for container log collection
  users.users.promtail.extraGroups = [ "docker" ];

  # Configure Twenty CRM service
  services.twenty-crm = {
    enable = true;
    serverUrl = "https://crm.workwithnextdesk.com";
    port = 3000;
    
    database = {
      user = "postgres";
      passwordFile = config.age.secrets.twenty-db-password.path;
    };
    
    appSecretFile = config.age.secrets.twenty-app-secret.path;
    
    auth.google = {
      enabled = true;
      clientIdFile = config.age.secrets.twenty-google-client-id.path;
      clientSecretFile = config.age.secrets.twenty-google-client-secret.path;
      callbackUrl = "https://crm.workwithnextdesk.com/auth/google/redirect";
      apisCallbackUrl = "https://crm.workwithnextdesk.com/auth/google-apis/get-access-token";
    };
    auth.microsoft.enabled = false;
    messagingProviderGmailEnabled = true;
    calendarProviderGoogleEnabled = true;
    email = {
      driver = "smtp";
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        secure = true;
        user = "melbourne@workwithnextdesk.com";
        passwordFile = config.age.secrets.twenty-smtp-password.path;
        from = "noreply@workwithnextdesk.com";
      };
    };
  };

  # Configure Ghost CMS service
  services.ghost-cms = {
    enable = true;
    url = "https://cms.workwithnextdesk.com";
    port = 8080;
    
    database = {
      client = "mysql";
      host = "db";
      user = "root";
      database = "ghost";
      passwordFile = config.age.secrets.ghost-db-password.path;
    };
    
    mail = {
      transport = "SMTP";
      from = "NextDesk <noreply@workwithnextdesk.com>";
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        secure = false;  # Use STARTTLS
        user = "melbourne@workwithnextdesk.com";
        passwordFile = config.age.secrets.ghost-smtp-password.path;
      };
    };
    
    nodeEnv = "production";
  };

  # Configure Outline Wiki service
  services.outline-wiki = {
    enable = true;
    url = "https://wiki.workwithnextdesk.com";
    port = 3001;
    
    secretKeyFile = config.age.secrets.outline-secret-key.path;
    utilsSecretFile = config.age.secrets.outline-utils-secret.path;
    
    database = {
      host = "twenty-db-1";
      port = 5432;
      user = "postgres";
      passwordFile = config.age.secrets.outline-db-password.path;
      database = "outline";
    };
    
    redis = {
      host = "twenty-redis-1";
      port = 6379;
    };
    
    auth.google = {
      enabled = true;
      clientIdFile = config.age.secrets.outline-google-client-id.path;
      clientSecretFile = config.age.secrets.outline-google-client-secret.path;
    };
    
    smtp = {
      enabled = true;
      host = "smtp.gmail.com";
      port = 587;
      user = "melbourne@workwithnextdesk.com";
      passwordFile = config.age.secrets.outline-smtp-password.path;
      fromEmail = "noreply@workwithnextdesk.com";
      replyEmail = "noreply@workwithnextdesk.com";
    };
    
    slack = {
      enabled = true;
      appId = "A0W3UMKBQ";
      messageActions = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = {
      imports = [
        ../../users/melbournebaldove/core.nix
      ];
    };
  };

  system.stateVersion = "24.11";
}