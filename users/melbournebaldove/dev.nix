
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
  
  # Simple shell wrapper for @google/gemini-cli
  gemini-cli = pkgs.writeShellScriptBin "gemini" ''
    # Use npx to run @google/gemini-cli
    exec ${pkgs.nodejs}/bin/npx --yes @google/gemini-cli@latest "$@"
  '';
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
  ];


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
