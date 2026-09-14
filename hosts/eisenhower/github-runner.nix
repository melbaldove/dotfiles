{ lib, pkgs, ... }:
let
  runner = pkgs.github-runner;
  runnerHome = "/var/lib/github-runners/eisenhower-ios";
in
{
  # The upstream runner service requires nix.enable. Determinate owns Nix here.
  users.knownUsers = [ "_github-runner" ];
  users.knownGroups = [ "_github-runner" ];
  users.groups._github-runner.gid = 533;
  users.users._github-runner = {
    uid = 533;
    gid = 533;
    home = runnerHome;
    shell = "/bin/bash";
    description = "Hey You iOS CI runner";
  };

  system.activationScripts.launchd.text = lib.mkBefore ''
    /usr/bin/install -d -m 0700 -o _github-runner -g _github-runner \
      ${runnerHome} ${runnerHome}/.ssh ${runnerHome}/Library/Keychains \
      ${runnerHome}/work ${runnerHome}/tmp /var/log/github-runners/eisenhower-ios
  '';

  launchd.daemons.github-runner-eisenhower-ios = {
    path = with pkgs; [ bash coreutils git gnutar gzip openssh curl ruby_3_3 ];
    environment = {
      HOME = runnerHome;
      RUNNER_ROOT = runnerHome;
      TMPDIR = "${runnerHome}/tmp";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
      NIX_REMOTE = "daemon";
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 = "true";
    };
    script = ''
      set -euo pipefail
      export PATH="/nix/var/nix/profiles/default/bin:$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
      cd ${runnerHome}
      if [[ ! -f .runner ]]; then
        if [[ ! -s registration-token ]]; then
          echo "Provision a repository registration token at ${runnerHome}/registration-token."
          exit 1
        fi
        ${runner}/bin/config.sh --unattended --disableupdate \
          --url https://github.com/heyyou/iphone-app-swift \
          --name eisenhower-ios --labels eisenhower,ios,nix \
          --work ${runnerHome}/work --token "$(< registration-token)"
        rm registration-token
      fi
      exec ${runner}/bin/Runner.Listener run --startuptype service
    '';
    serviceConfig = {
      UserName = "_github-runner";
      GroupName = "_github-runner";
      WorkingDirectory = runnerHome;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      SessionCreate = true;
      # Match nix-darwin's runner service; builds need normal CPU and disk access.
      ProcessType = "Interactive";
      StandardOutPath = "/var/log/github-runners/eisenhower-ios/stdout.log";
      StandardErrorPath = "/var/log/github-runners/eisenhower-ios/stderr.log";
    };
  };
}
