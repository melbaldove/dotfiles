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
      
      limits_config = {
        allow_structured_metadata = false;
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
          cache_location = "/var/lib/loki/cache";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      
      compactor = {
        working_directory = "/var/lib/loki/compactor";
      };
    };
  };
  
  # Firewall configuration - allow Loki port on VPN interfaces
  networking.firewall.interfaces.wg-personal.allowedTCPPorts = [ 3100 ];
  networking.firewall.interfaces.wg-startup.allowedTCPPorts = [ 3100 ];
}