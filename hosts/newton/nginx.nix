{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    
    # Configure nginx to log to systemd journal
    logError = "stderr";  # Default - logs to systemd journal
    
    # Configure access logs to also go to systemd journal
    commonHttpConfig = ''
      access_log syslog:server=unix:/dev/log,tag=nginx_access combined;
      
      # WebSocket connection upgrade mapping
      map $http_upgrade $connection_upgrade {
        default upgrade;
        "" close;
      }
    '';

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

      "wiki.workwithnextdesk.com" = {
        enableACME = true;
        forceSSL = true;
        
        locations."/" = {
          proxyPass = "http://localhost:3001";
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

      "n8n.workwithnextdesk.com" = {
        enableACME = true;
        forceSSL = true;
        
        locations."/" = {
          proxyPass = "http://localhost:5678";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_buffering off;
            
            # Forward all headers including Authorization and cookies
            proxy_pass_request_headers on;
            proxy_set_header Authorization $http_authorization;
            proxy_set_header Cookie $http_cookie;
            
            # WebSocket support for n8n
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
            proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
            proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;
            
            # Increase timeouts for long-running workflows
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
          '';
        };
      };
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