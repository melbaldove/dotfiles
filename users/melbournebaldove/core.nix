
{
  config, pkgs, self, ...
}:
{
  home.username = "melbournebaldove";
  home.homeDirectory = pkgs.lib.mkDefault "/Users/melbournebaldove";
  home.stateVersion = "24.11";

  home.shell.enableShellIntegration = true;

  programs = {
    bash = {
      enable = true;
      bashrcExtra = ''
        # Custom prompt showing username and current directory
        export PS1="\u:\w$ "
      '';
    };
    home-manager.enable = true;

    nushell = {
      enable = true;
      configFile.source = config.lib.file.mkOutOfStoreSymlink "${self}/nushell/config.nu";
    };

    git = {
      enable = true;
      extraConfig = {
        core = {
          editor = "vim";
          excludesfile = "~/.gitignore";
        };
        user = {
          name = "Melbourne Baldove";
          email = "melbournebaldove@gmail.com";
        };
        push = {
          autosetupremote = true;
        };
      };
    };
  };

  home.file = {
    ".gitignore".source = config.lib.file.mkOutOfStoreSymlink "${self}/git/.gitignore-config";
  };
}
