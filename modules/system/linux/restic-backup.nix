{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.restic-backup;
  backupUser = "backup";
  sshKeyPath = "/var/lib/${backupUser}/.ssh/id_backup";
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
    
    sshKeyFile = mkOption {
      type = types.str;
      description = "Path to SSH private key file";
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
        assertion = cfg.sshKeyFile != "";
        message = "restic-backup: sshKeyFile must be specified";
      }
      {
        assertion = cfg.paths != [];
        message = "restic-backup: at least one path must be specified";
      }
    ];

    environment.systemPackages = [ pkgs.restic ];
    
    # Create backup user with consistent name
    users.users.${backupUser} = {
      isSystemUser = true;
      group = backupUser;
      home = "/var/lib/${backupUser}";
      createHome = true;
      extraGroups = [ "docker" ];
    };
    
    users.groups.${backupUser} = {};
    
    # SSH configuration for backup user
    system.activationScripts.backup-ssh-config = ''
      mkdir -p /var/lib/${backupUser}/.ssh
      chown ${backupUser}:${backupUser} /var/lib/${backupUser}/.ssh
      chmod 700 /var/lib/${backupUser}/.ssh
      
      # Create SSH config
      cat > /var/lib/${backupUser}/.ssh/config <<'EOF'
      Host *
        StrictHostKeyChecking accept-new
        UserKnownHostsFile /var/lib/${backupUser}/.ssh/known_hosts
        IdentityFile ${sshKeyPath}
      EOF
      chown ${backupUser}:${backupUser} /var/lib/${backupUser}/.ssh/config
      chmod 600 /var/lib/${backupUser}/.ssh/config
    '';

    systemd.services.restic-backup = {
      description = "Restic backup";
      after = [ "network.target" ];
      wants = [ "network-online.target" ];
      path = with pkgs; [ restic openssh ];
      
      serviceConfig = {
        Type = "oneshot";
        User = backupUser;
        Group = backupUser;
        ExecStart = pkgs.writeShellScript "restic-backup" ''
          set -euo pipefail
          
          # Validate SSH key exists
          if [[ ! -f "${sshKeyPath}" ]]; then
            echo "ERROR: SSH key not found at ${sshKeyPath}"
            exit 1
          fi
          
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