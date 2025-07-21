{ config, pkgs, ... }:

{
  age.secrets.alertmanager-slack-webhook.file = ../../../secrets/alertmanager-slack-webhook.age;

  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;
    listenAddress = "localhost";
    
    configuration = {
      global = {
        slack_api_url_file = config.age.secrets.alertmanager-slack-webhook.path;
      };
      
      route = {
        group_by = [ "cluster" "service" "severity" ];
        group_wait = "10s";
        group_interval = "10s";
        repeat_interval = "1h";
        receiver = "default";
        routes = [
          {
            matchers = [ "severity=~critical|warning" ];
            receiver = "slack-alerts";
            continue = true;
          }
        ];
      };
      
      receivers = [
        {
          name = "default";
        }
        {
          name = "slack-alerts";
          slack_configs = [
            {
              channel = "#alerts";
              title = "{{ .GroupLabels.cluster }} Alert";
              text = ''
                {{ range .Alerts }}
                *{{ .Annotations.summary }}*
                {{ .Annotations.description }}
                *Labels:* {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
                {{ end }}
              '';
              color = ''{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'';
            }
          ];
        }
      ];
    };
  };
  
  networking.firewall.allowedTCPPorts = [ 9093 ];
}