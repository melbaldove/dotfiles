{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "crm.workwithnextdesk.com" = {
        enableACME = true;
        forceSSL = true;
        
        locations."/" = {
          proxyPass = "http://localhost:3000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      "cms.workwithnextdesk.com" = {
        enableACME = true;
        forceSSL = true;
        
        locations."/" = {
          return = "301 https://$host/ghost/";
        };
        
        locations."~* ^/(ghost|content|assets|public)(/.*)?$" = {
          proxyPass = "http://localhost:8080";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_buffering off;
          '';
        };
      };

      # Add more virtual hosts here for other services
      # "api.workwithnextdesk.com" = { ... };
      # "docs.workwithnextdesk.com" = { ... };
    };
  };

  # ACME certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@workwithnextdesk.com";
  };

  # Open firewall for web services
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}