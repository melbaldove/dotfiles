{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.restic-backup;
  backupUser = "backup";
in {
  options.services.restic-backup = {
    enable = mkEnableOption "restic backup service";
    
    repository = mkOption {
      type = types.str;
      description = "Restic repository location";
    };
    
    passwordFile = mkOption {
      type = types.str;
      description = "Path to repository password file";
    };
    
    
    paths = mkOption {
      type = types.listOf types.str;
      description = "Paths to backup";
    };
    
    pruneOpts = mkOption {
      type = types.listOf types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 4" 
        "--keep-monthly 12"
        "--keep-yearly 2"
      ];
      description = "Retention options for pruning";
    };
  };
  
  config = mkIf cfg.enable {
    # Assertions for validation
    assertions = [
      {
        assertion = cfg.passwordFile != "";
        message = "restic-backup: passwordFile must be specified";
      }
      {
        assertion = cfg.paths != [];
        message = "restic-backup: at least one path must be specified";
      }
    ];

    environment.systemPackages = [ pkgs.restic ];
    

    systemd.services.restic-backup = {
      description = "Restic backup";
      after = [ "network.target" ];
      wants = [ "network-online.target" ];
      path = with pkgs; [ restic ];
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "restic-backup" ''
          set -euo pipefail
          
          # Initialize repository if it doesn't exist
          if ! restic snapshots &>/dev/null; then
            echo "Initializing restic repository..."
            restic init
          fi
          
          # Run backup with error handling
          echo "Starting backup of: ${concatStringsSep " " cfg.paths}"
          restic backup ${concatStringsSep " " cfg.paths} || {
            echo "ERROR: Backup failed"
            exit 1
          }
          
          # Prune old snapshots
          echo "Pruning old snapshots..."
          restic forget ${concatStringsSep " " cfg.pruneOpts} --prune || {
            echo "WARNING: Pruning failed, but backup succeeded"
          }
          
          echo "Backup completed successfully"
        '';
        Environment = [
          "RESTIC_REPOSITORY=${cfg.repository}"
          "RESTIC_PASSWORD_FILE=${cfg.passwordFile}"
        ];
      };
    };
    
    systemd.timers.restic-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}