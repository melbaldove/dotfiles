{ config, pkgs, ... }:
let
  emacsConfig = "${config.home.homeDirectory}/.dotfiles/emacs/init.el";
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-basic
      luatex
      fontspec
      xcolor
      mylatexformat
      preview
      dvisvgm dvipng # for preview and export as html
      wrapfig amsmath ulem hyperref capt-of;
  });
in
{
  home.username = "melbournebaldove";
  home.homeDirectory = "/Users/melbournebaldove";
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    tex
    aider-chat
    claude-code
    imagemagick
    gh
    ripgrep
    ast-grep
    nodejs
  ];
  home.shell.enableShellIntegration = true;
  
  home.file.".npmrc".text = ''
    prefix = ${config.home.homeDirectory}/.npm-global
  '';
  
  home.sessionVariables = {
    PATH = "$PATH:${config.home.homeDirectory}/.npm-global/bin";
  };
  
  home.activation.installNpmPackages = config.lib.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
    $DRY_RUN_CMD env PATH=${pkgs.nodejs}/bin:/bin:/usr/bin ${pkgs.nodejs}/bin/npm install -g @google/gemini-cli --prefix ${config.home.homeDirectory}/.npm-global
  '';

  programs = {
    # Let Home Manager install and manage itself.
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
    
    emacs = {
      enable = true;
      package = pkgs.emacs-unstable;
      extraPackages = epkgs: [
        epkgs.use-package
      ];
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      silent = true;
      nix-direnv.enable = true;
    };

    gpg = {
      enable = true;
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
  
  services = {
    emacs = {
      enable = true;
      package = pkgs.emacs-unstable;
      defaultEditor = true;
    };
  };

  home.file = {
    ".claude/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/.claude-global/CLAUDE.md";
    };
    ".claude/commands" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/.claude-global/commands";
    };
    ".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/.claude-global/settings.json";
    };
    ".claude/shared" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/.claude-global/shared";
    };
  };

  xdg = {
    enable = true;
    configFile = {
      "nix" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/nix";
        recursive = true;
      };
      "emacs" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/emacs";
        recursive = true;
      };
      "ghostty" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/ghostty";
        recursive = true;
      };
    };
  };
}
