
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
        alias rebuild='sudo darwin-rebuild --impure switch'
      '';
    };
    home-manager.enable = true;

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
    ".claude/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/CLAUDE.md";
    };
    ".claude/commands" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/commands";
    };
    ".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/settings.json";
    };
    ".claude/shared" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/shared";
    };
    ".gitignore" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/git/.gitignore-config";
    };
    ".gemini/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/gemini/settings.json";
    };
    ".gemini/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/CLAUDE.md";
    };
    ".gemini/commands" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/commands";
    };
    ".gemini/shared" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/shared";
    };
  };

  xdg = {
    enable = true;
    configFile = {
      "ghostty" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/ghostty";
        recursive = true;
      };
      "emacs/init.el" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/emacs/init.el";
      };
      "emacs/.emacs.custom.el" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/emacs/.emacs.custom.el";
      };
      "emacs/snippets" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/emacs/snippets";
      };
    };
  };
}
