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
      path = with pkgs; [ restic bc gawk coreutils ];
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "restic-backup" ''
          set -euo pipefail
          
          METRICS_FILE="/var/lib/node_exporter/textfile_collector/restic.prom"
          TEMP_METRICS="/tmp/restic_metrics.$$"
          
          # Function to write metrics
          write_metrics() {
            local status="$1"
            local exit_code="$2"
            local start_time="$3"
            local end_time="$(date +%s)"
            local duration=$((end_time - start_time))
            
            cat > "$TEMP_METRICS" << EOF
          # HELP restic_backup_success Whether the last backup was successful (1 = success, 0 = failure)
          # TYPE restic_backup_success gauge
          restic_backup_success{repository="${cfg.repository}"} $status
          
          # HELP restic_backup_exit_code Exit code of the last backup
          # TYPE restic_backup_exit_code gauge
          restic_backup_exit_code{repository="${cfg.repository}"} $exit_code
          
          # HELP restic_backup_duration_seconds Duration of the last backup in seconds
          # TYPE restic_backup_duration_seconds gauge
          restic_backup_duration_seconds{repository="${cfg.repository}"} $duration
          
          # HELP restic_backup_timestamp_seconds Timestamp of the last backup completion
          # TYPE restic_backup_timestamp_seconds gauge
          restic_backup_timestamp_seconds{repository="${cfg.repository}"} $end_time
          EOF
            
            mkdir -p "$(dirname "$METRICS_FILE")"
            mv "$TEMP_METRICS" "$METRICS_FILE"
          }
          
          START_TIME=$(date +%s)
          
          # Initialize repository if it doesn't exist
          if ! restic snapshots &>/dev/null; then
            echo "Initializing restic repository..."
            restic init
          fi
          
          # Run backup with error handling
          echo "Starting backup of: ${concatStringsSep " " cfg.paths}"
          if restic backup ${concatStringsSep " " cfg.paths}; then
            echo "Backup completed successfully"
            
            # Get repository stats
            restic stats --mode restore-size > /tmp/restic_stats.$$
            # Parse size and convert to bytes
            SIZE_LINE=$(grep "Total Size:" /tmp/restic_stats.$$ || echo "0 B")
            SIZE_VALUE=$(echo "$SIZE_LINE" | awk '{print $3}')
            SIZE_UNIT=$(echo "$SIZE_LINE" | awk '{print $4}')
            
            # Convert to bytes
            case "$SIZE_UNIT" in
              "B") RESTORE_SIZE="$SIZE_VALUE" ;;
              "KiB") RESTORE_SIZE=$(echo "$SIZE_VALUE * 1024" | bc -l | cut -d. -f1) ;;
              "MiB") RESTORE_SIZE=$(echo "$SIZE_VALUE * 1048576" | bc -l | cut -d. -f1) ;;
              "GiB") RESTORE_SIZE=$(echo "$SIZE_VALUE * 1073741824" | bc -l | cut -d. -f1) ;;
              "TiB") RESTORE_SIZE=$(echo "$SIZE_VALUE * 1099511627776" | bc -l | cut -d. -f1) ;;
              *) RESTORE_SIZE="0" ;;
            esac
            
            rm -f /tmp/restic_stats.$$
            
            # Prune old snapshots
            echo "Pruning old snapshots..."
            if restic forget ${concatStringsSep " " cfg.pruneOpts} --prune; then
              echo "Pruning completed successfully"
            else
              echo "WARNING: Pruning failed, but backup succeeded"
            fi
            
            # Write success metrics with additional stats
            cat > "$TEMP_METRICS" << EOF
          # HELP restic_backup_success Whether the last backup was successful (1 = success, 0 = failure)
          # TYPE restic_backup_success gauge
          restic_backup_success{repository="${cfg.repository}"} 1
          
          # HELP restic_backup_exit_code Exit code of the last backup
          # TYPE restic_backup_exit_code gauge
          restic_backup_exit_code{repository="${cfg.repository}"} 0
          
          # HELP restic_backup_duration_seconds Duration of the last backup in seconds
          # TYPE restic_backup_duration_seconds gauge
          restic_backup_duration_seconds{repository="${cfg.repository}"} $(($(date +%s) - START_TIME))
          
          # HELP restic_backup_timestamp_seconds Timestamp of the last backup completion
          # TYPE restic_backup_timestamp_seconds gauge
          restic_backup_timestamp_seconds{repository="${cfg.repository}"} $(date +%s)
          
          # HELP restic_backup_restore_size_bytes Total restore size of the repository
          # TYPE restic_backup_restore_size_bytes gauge
          restic_backup_restore_size_bytes{repository="${cfg.repository}"} $RESTORE_SIZE
          EOF
            
            mkdir -p "$(dirname "$METRICS_FILE")"
            mv "$TEMP_METRICS" "$METRICS_FILE"
            
          else
            echo "ERROR: Backup failed"
            write_metrics "0" "$?" "$START_TIME"
            exit 1
          fi
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