
{
  config, pkgs, ...
}:
{
  home.username = "melbournebaldove";
  home.homeDirectory = "/Users/melbournebaldove";
  home.stateVersion = "24.11";

  home.shell.enableShellIntegration = true;

  programs = {
    bash = {
      enable = true;
      bashrcExtra = ''
        # Custom prompt showing username and current directory
        export PS1="\u:\w$ "
        
        # Alias for ast-grep
        alias sg='ast-grep'
        
        # Alias for darwin-rebuild
        alias rebuild='sudo darwin-rebuild switch'
      '';
    };
    home-manager.enable = true;

    nushell = {
      enable = true;
      configFile.source = ../../nushell/config.nu;
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
    ".claude/CLAUDE.md".source = ../../claude/CLAUDE.md;
    ".claude/commands".source = ../../claude/commands;
    ".claude/settings.json".source = ../../claude/settings.json;
    ".claude/shared".source = ../../claude/shared;
    ".gitignore".source = ../../git/.gitignore-config;
    ".gemini/settings.json".source = ../../gemini/settings.json;
    ".gemini/CLAUDE.md".source = ../../claude/CLAUDE.md;
    ".gemini/commands".source = ../../claude/commands;
    ".gemini/shared".source = ../../claude/shared;
  };

  xdg = {
    enable = true;
    configFile = {
      "ghostty" = {
        source = ../../ghostty;
        recursive = true;
      };
      "emacs/init.el".source = ../../emacs/init.el;
      "emacs/.emacs.custom.el".source = ../../emacs/.emacs.custom.el;
      "emacs/snippets".source = ../../emacs/snippets;
    };
  };
}
