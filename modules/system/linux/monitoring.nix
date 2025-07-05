{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "127.0.0.1";
    
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
  };

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "127.0.0.1";
  };
}