{ config, pkgs, ... }:

{
  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3100;
        http_listen_address = "10.0.0.1";
        grpc_listen_port = 9095;
        grpc_listen_address = "10.0.0.1";
      };
      
      auth_enabled = false;
      
      ingester = {
        wal = {
          enabled = true;
          dir = "/var/lib/loki/wal";
        };
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
        chunk_block_size = 262144;
        chunk_target_size = 1048576;
        chunk_retain_period = "30s";
      };
      
      schema_config = {
        configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v12";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
      
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
          shared_store = "filesystem";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        shared_store = "filesystem";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
      };
      
      limits_config = {
        retention_period = "336h"; # 14 days
        enforce_metric_name = false;
        reject_old_samples = true;
        reject_old_samples_max_age = "168h"; # 7 days
        max_line_size = 256000;
        max_streams_per_user = 10000;
        ingestion_rate_mb = 4;
        ingestion_burst_size_mb = 6;
      };
      
      chunk_store_config = {
        max_look_back_period = "0s";
      };
      
      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };
      
      ruler = {
        storage = {
          type = "local";
          local = {
            directory = "/var/lib/loki/rules";
          };
        };
        rule_path = "/var/lib/loki/rules";
        alertmanager_url = "http://localhost:9093";
        ring = {
          kvstore = {
            store = "inmemory";
          };
        };
        enable_api = true;
      };
      
      analytics = {
        reporting_enabled = false;
      };
    };
  };
  
  # Firewall configuration - allow Loki ports on VPN interfaces
  networking.firewall.interfaces.wg-personal.allowedTCPPorts = [ 3100 9095 ];
  networking.firewall.interfaces.wg-startup.allowedTCPPorts = [ 3100 9095 ];
  
  # Ensure loki data directories exist with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/loki 0755 loki loki -"
    "d /var/lib/loki/chunks 0755 loki loki -"
    "d /var/lib/loki/wal 0755 loki loki -"
    "d /var/lib/loki/tsdb-index 0755 loki loki -"
    "d /var/lib/loki/tsdb-cache 0755 loki loki -"
    "d /var/lib/loki/compactor 0755 loki loki -"
    "d /var/lib/loki/rules 0755 loki loki -"
  ];
}