
{
  config, pkgs, ...
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
  ];

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
  };
  
  services = {
    emacs = {
      enable = true;
      package = pkgs.emacs-unstable;
      defaultEditor = true;
    };
  };
}
