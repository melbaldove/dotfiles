{ pkgs, ... }:
let
  watchdog = pkgs.writeShellApplication {
    name = "eisenhower-wifi-watchdog";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      gnused
    ];
    text = builtins.readFile ./wifi-watchdog.sh;
  };
in
{
  environment.systemPackages = [ watchdog ];

  launchd.daemons.eisenhower-wifi-watchdog.serviceConfig = {
    Label = "com.eisenhower.wifi-watchdog";
    ProgramArguments = [ "${watchdog}/bin/eisenhower-wifi-watchdog" ];
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Background";
    ThrottleInterval = 30;
    StandardOutPath = "/var/log/eisenhower-wifi-watchdog.log";
    StandardErrorPath = "/var/log/eisenhower-wifi-watchdog.error.log";
  };
}
