
{
  config, pkgs, self, ...
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
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/CLAUDE.md";
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/commands";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/settings.json";
    ".claude/shared".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/shared";
    ".gitignore".source = config.lib.file.mkOutOfStoreSymlink "${self}/git/.gitignore-config";
    ".gemini/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${self}/gemini/settings.json";
    ".gemini/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/CLAUDE.md";
    ".gemini/commands".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/commands";
    ".gemini/shared".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/shared";
    ".hammerspoon/init.lua".source = config.lib.file.mkOutOfStoreSymlink "${self}/hammerspoon/init.lua";
  };

  xdg = {
    enable = true;
    configFile = {
      "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${self}/ghostty";
      "emacs/init.el".source = config.lib.file.mkOutOfStoreSymlink "${self}/emacs/init.el";
      "emacs/.emacs.custom.el".source = config.lib.file.mkOutOfStoreSymlink "${self}/emacs/.emacs.custom.el";
      "emacs/snippets".source = config.lib.file.mkOutOfStoreSymlink "${self}/emacs/snippets";
    };
  };
}
