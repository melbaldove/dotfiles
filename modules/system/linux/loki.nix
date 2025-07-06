{ config, pkgs, ... }:

{
  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3100;
        http_listen_address = "10.0.0.1";
      };
      
      auth_enabled = false;
      
      # Common configuration for all components
      common = {
        path_prefix = "/var/lib/loki";
      };
      
      ingester = {
        lifecycler = {
          address = "10.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
          final_sleep = "0s";
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_retain_period = "30s";
      };
      
      schema_config = {
        configs = [
          {
            from = "2020-10-24";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
      
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/index";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      
      limits_config = {
        retention_period = "336h"; # 14 days
        reject_old_samples = true;
        reject_old_samples_max_age = "168h"; # 7 days
      };
      
      compactor = {
        working_directory = "/var/lib/loki/compactor";
      };
      
      memberlist = {
        join_members = [];
      };
      
      analytics = {
        reporting_enabled = false;
      };
    };
  };
  
  # Firewall configuration - allow Loki port on VPN interfaces
  networking.firewall.interfaces.wg-personal.allowedTCPPorts = [ 3100 ];
  networking.firewall.interfaces.wg-startup.allowedTCPPorts = [ 3100 ];
}