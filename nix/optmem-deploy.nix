{ system, host }:
let
  root = ../.;
  flake = builtins.getFlake (toString root);
  pkgs = import flake.inputs.nixpkgs { inherit system; config.allowUnfree = true; };
  home = flake.inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inputs = flake.inputs // { self = root; };
      osConfig.networking.hostName = host;
    };
    modules = [
      ../users/melbournebaldove/claude.nix
      {
        home.username = "melbournebaldove";
        home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/melbournebaldove" else "/home/melbournebaldove";
        home.stateVersion = "24.11";
      }
    ];
  };
  files = home.config.home.file;
  selected = [ ".optmem/memo" ".local/bin/memo" ".claude/CLAUDE.md" ".claude-sphere/CLAUDE.md" ".codex/AGENTS.md" ".gemini/AGENTS.md" ]
    ++ pkgs.lib.optional (host == "eisenhower") ".optmem/snapshot";
  fileLinks = map (name: { inherit name; path = files.${name}.source; }) selected;
  backup = pkgs.lib.findFirst (package: package.name == "optmem-backup") null home.config.home.packages;
  unit = name: value: {
    inherit name;
    path = pkgs.writeText (baseNameOf name) (pkgs.lib.generators.toINI { listsAsDuplicateKeys = true; } value);
  };
in
assert builtins.elem host [ "eisenhower" "einstein" "turing" ];
pkgs.linkFarm "optmem-deploy-${host}" (fileLinks ++ pkgs.lib.optionals (host == "einstein") [
  { name = ".local/bin/optmem-backup"; path = "${backup}/bin/optmem-backup"; }
  (unit ".config/systemd/user/optmem-backup.service" home.config.systemd.user.services.optmem-backup)
  (unit ".config/systemd/user/optmem-backup.timer" home.config.systemd.user.timers.optmem-backup)
])
