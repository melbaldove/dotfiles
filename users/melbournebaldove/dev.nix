
{
  config, pkgs, self, ...
}:
let
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
  home.packages = with pkgs; [
    tex
    aider-chat
    claude-code
    imagemagick
    gh
    ripgrep
    ast-grep
    nodejs
    gemini-cli
    nmap
    deploy-rs
  ];

  # Development-specific bash aliases
  programs.bash.bashrcExtra = ''
    # Alias for ast-grep
    alias sg='ast-grep'
  '';


  programs = {
    emacs = {
      enable = true;
      package = pkgs.emacs-unstable;
      extraPackages = epkgs: [
        epkgs.use-package
      ];
    };

    nushell = {
      enable = true;
      configFile.source = config.lib.file.mkOutOfStoreSymlink "${self}/nushell/config.nu";
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      silent = true;
      nix-direnv.enable = true;
    };

    gpg = {
      enable = true;
    };
  };
  
  services = {
    emacs = {
      enable = true;
      package = pkgs.emacs-unstable;
      defaultEditor = true;
    };
  };

  # AI assistant configurations
  home.file = {
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/CLAUDE.md";
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/commands";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/settings.json";
    ".claude/shared".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/shared";
    ".gemini/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${self}/gemini/settings.json";
    ".gemini/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/CLAUDE.md";
    ".gemini/commands".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/commands";
    ".gemini/shared".source = config.lib.file.mkOutOfStoreSymlink "${self}/claude/shared";
  };

  # Emacs configuration
  xdg.configFile = {
    "emacs/snippets".source = config.lib.file.mkOutOfStoreSymlink "${self}/emacs/snippets";
  };

  # Manual activation script to create writable symlinks for Emacs files
  home.activation.linkEmacsFiles = config.lib.dag.entryAfter ["writeBoundary"] ''
    run rm -f ${config.xdg.configHome}/emacs/init.el
    run ln -sf ${config.home.homeDirectory}/.dotfiles/emacs/init.el ${config.xdg.configHome}/emacs/init.el
    run rm -f ${config.xdg.configHome}/emacs/.emacs.custom.el
    run ln -sf ${config.home.homeDirectory}/.dotfiles/emacs/.emacs.custom.el ${config.xdg.configHome}/emacs/.emacs.custom.el
  '';
}
