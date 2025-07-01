{ config, lib, pkgs, ... }:

{
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    trustedInterfaces = [ "wg0" ];
  };

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ "wg0" ];
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.0.1/24" ];
      listenPort = 51820;

      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
      '';

      privateKeyFile = "/etc/wireguard/private";

      peers = [
        {
          # Einstein home server/gateway
          publicKey = "S9gL9Rg+/JtzcwwUOQT4fJFjm4x/ONrGwzdjeH85jHc=";
          allowedIPs = [ "10.0.0.2/32" "192.168.50.0/24" ];
        }
        {
          # Turing client
          publicKey = "w/iizjwjWD6c3zmGYcCL0/ThHCW0odzEVbiq2FRQdBg=";
          allowedIPs = [ "10.0.0.3/32" ];
        }
      ];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}