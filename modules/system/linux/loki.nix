{ config, pkgs, ... }:

{
  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3100;
        http_listen_address = "0.0.0.0";  # Listen on all interfaces to accept connections from both VPN networks
      };
      
      auth_enabled = false;
      
      limits_config = {
        allow_structured_metadata = true; # Enable with TSDB backend
        retention_period = "168h"; # 7 days
        reject_old_samples = true;
        reject_old_samples_max_age = "72h"; # 3 days
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
        chunk_idle_period = "2h";    # Conservative start
        max_chunk_age = "2h";        # Conservative start  
        chunk_retain_period = "60s"; # Conservative start
      };
      
      schema_config = {
        configs = [
          {
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "tsdb_index_";
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
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb";
          cache_location = "/var/lib/loki/tsdb-cache";
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