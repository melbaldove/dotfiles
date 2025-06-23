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
  ];
  home.shell.enableShellIntegration = true;

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
