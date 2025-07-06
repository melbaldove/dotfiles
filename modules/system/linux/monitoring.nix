{ config, pkgs, ... }:

{
  imports = [
    ./loki.nix
  ];

  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "127.0.0.1";
    retentionTime = "30d";
    
    scrapeConfigs = [
      {
        job_name = "personal";
        static_configs = [{
          targets = [ 
            "127.0.0.1:9100"      # shannon itself
            "10.0.0.2:9100"       # einstein
            "10.0.0.3:9100"       # turing
          ];
        }];
      }
      {
        job_name = "startup";
        static_configs = [{
          targets = [ "10.0.1.2:9100" ]; # newton
        }];
      }
      {
        job_name = "startup-docker";
        static_configs = [{
          targets = [ "10.0.1.2:9200" ]; # newton cadvisor
        }];
      }
      {
        job_name = "loki";
        static_configs = [{
          targets = [ "127.0.0.1:3100" ]; # loki itself
        }];
      }
      {
        job_name = "promtail";
        static_configs = [{
          targets = [
            "127.0.0.1:9080"      # shannon promtail
            "10.0.0.2:9080"       # einstein promtail
            "10.0.1.2:9080"       # newton promtail
          ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "10.0.0.1";
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "admin";
      };
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9090";
            isDefault = true;
            jsonData = {
              timeInterval = "5s";
            };
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://localhost:3100";
            isDefault = false;
            jsonData = {
              maxLines = 1000;
            };
          }
        ];
      };
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "127.0.0.1";
  };
}