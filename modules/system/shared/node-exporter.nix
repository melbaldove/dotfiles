{ config, pkgs, lib, ... }:

{
  options.monitoring.nodeExporter.listenAddress = lib.mkOption {
    type = lib.types.str;
    description = "IP address for node exporter to bind to";
  };

  config = {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = config.monitoring.nodeExporter.listenAddress;
    };
  };
}