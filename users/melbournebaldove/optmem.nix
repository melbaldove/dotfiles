{ config, pkgs, lib, osConfig, ... }:
let
  host = osConfig.networking.hostName;
  enabled = builtins.elem host [ "eisenhower" "einstein" "turing" ];
  server = host == "eisenhower";
  backupHost = host == "einstein";
  upstream = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/VictorTaelin/OptMem/1fb164cf39028047781f72ac3bb1e5a691c1dcb0/memo";
    hash = "sha256-PcEg0BvjEV72Jn6rQQPnkJ/IMNYie1SfIJkbqZnun/s=";
  };
  knownHosts = pkgs.writeText "optmem-known-hosts" ''
    100.89.96.77 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvL84a8GO4rz/8EqVVh6kcXpw6iFtYdHf9JPeYYRjn5
  '';
  runner = "${pkgs.python3}/bin/python3 ${../../scripts/optmem.py}";
  remote = "${pkgs.openssh}/bin/ssh ${knownHosts}";
  memo = pkgs.writeShellScriptBin "memo" ''
    exec ${runner} ${if server then "server ${upstream}" else "client ${remote}"} "$@"
  '';
  snapshot = pkgs.writeShellScript "optmem-snapshot" ''
    exec ${runner} snapshot
  '';
  backup = pkgs.writeShellScriptBin "optmem-backup" ''
    exec ${runner} backup ${remote}
  '';
in
{
  config = lib.mkIf enabled {
    home.packages = [ memo ] ++ lib.optional backupHost backup;
    home.file.".optmem/memo".source = "${memo}/bin/memo";
    home.file.".local/bin/memo".source = "${memo}/bin/memo";
    home.file.".optmem/snapshot" = lib.mkIf server { source = snapshot; };
    home.activation.optmem = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      $DRY_RUN_CMD chmod 700 "$HOME/.optmem"
      ${lib.optionalString server ''
        if [ ! -d "$HOME/.optmem/memory" ]; then
          $DRY_RUN_CMD ${memo}/bin/memo init > /dev/null
        fi
        $DRY_RUN_CMD chmod 700 "$HOME/.optmem/memory"
      ''}
    '';
    systemd.user.services.optmem-backup = lib.mkIf backupHost {
      Unit.Description = "Back up Eisenhower OptMem through Tailscale";
      Service = {
        Type = "oneshot";
        ExecStart = "${backup}/bin/optmem-backup";
        UMask = "0077";
      };
    };
    systemd.user.timers.optmem-backup = lib.mkIf backupHost {
      Unit.Description = "Daily OptMem backup";
      Timer = {
        OnCalendar = "daily";
        OnStartupSec = "5m";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
