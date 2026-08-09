{
  power.sleep = {
    computer = "never";
    allowSleepByPowerButton = false;
  };

  launchd.daemons.eisenhower-prevent-idle-sleep.serviceConfig = {
    Label = "com.eisenhower.prevent-idle-sleep";
    ProgramArguments = [
      "/usr/bin/caffeinate"
      "-i"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Background";
    StandardOutPath = "/var/log/eisenhower-prevent-idle-sleep.log";
    StandardErrorPath = "/var/log/eisenhower-prevent-idle-sleep.error.log";
  };
}
