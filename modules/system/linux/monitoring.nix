{ config, pkgs, ... }:

{
  imports = [
    ./loki.nix
  ];

  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "localhost";
    retentionTime = "30d";
    
    scrapeConfigs = [
      {
        job_name = "personal";
        static_configs = [{
          targets = [ 
            "localhost:9100"      # shannon itself
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
          targets = [ "localhost:3100" ]; # loki itself
        }];
      }
      {
        job_name = "promtail";
        static_configs = [{
          targets = [
            "localhost:9080"      # shannon promtail
            "10.0.0.2:9080"       # einstein promtail
            "10.0.1.2:9080"       # newton promtail
          ];
        }];
      }
      {
        job_name = "blackbox-exporter";
        static_configs = [{
          targets = [ "localhost:9115" ];
        }];
      }
      {
        job_name = "blackbox-http";
        static_configs = [{
          targets = [
            "https://crm.workwithnextdesk.com"
            "https://cms.workwithnextdesk.com"
          ];
        }];
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:9115";
          }
        ];
      }
      {
        job_name = "blackbox-ssl";
        static_configs = [{
          targets = [
            "crm.workwithnextdesk.com:443"
            "cms.workwithnextdesk.com:443"
          ];
        }];
        metrics_path = "/probe";
        params = {
          module = [ "tcp_tls" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:9115";
          }
        ];
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
    listenAddress = "localhost";
  };

  services.prometheus.exporters.blackbox = {
    enable = true;
    port = 9115;
    listenAddress = "localhost";
    configFile = pkgs.writeText "blackbox.yml" ''
      modules:
        http_2xx:
          prober: http
          timeout: 5s
          http:
            method: GET
            valid_status_codes: [200]
            fail_if_not_ssl: true
            preferred_ip_protocol: "ip4"
        tcp_tls:
          prober: tcp
          timeout: 5s
          tcp:
            tls: true
            tls_config:
              insecure_skip_verify: false
    '';
  };
}