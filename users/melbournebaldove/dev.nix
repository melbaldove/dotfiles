
{
  config, pkgs, lib, inputs, ...
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
  imports = [
    ./claude.nix
  ];

  home.packages = with pkgs; [
    tex
    imagemagick
    gh
    ripgrep
    ast-grep
    nodejs
    bun
    gemini-cli
    nmap
    deploy-rs
    wireguard-tools
    cmake
    libtool
    tree
    fzf
    gleam
(pkgs.writeShellScriptBin "opencode" ''
      exec ${pkgs.nodejs}/bin/npx opencode-ai@latest "$@"
    '')
    (pkgs.writeShellScriptBin "qwen-code" ''
      exec ${pkgs.nodejs}/bin/npx @qwen-code/qwen-code@latest "$@"
    '')
    inputs.agenix.packages.${pkgs.system}.default
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    go-ios
  ];

  # Development-specific bash aliases and setup
  programs.bash.bashrcExtra = ''
    # Alias for ast-grep
    alias sg='ast-grep'
    
    # Add .local/bin to PATH for glibtool
    export PATH="$HOME/.local/bin:$PATH"
  '';
  
  # Create glibtool wrapper for vterm compilation on macOS
  home.file.".local/bin/glibtool" = lib.mkIf pkgs.stdenv.isDarwin {
    executable = true;
    text = ''
      #!/bin/sh
      exec ${pkgs.libtool}/bin/libtool "$@"
    '';
  };


  programs = {
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

  # Gemini assistant configurations (Claude configs are now in claude.nix)
  home.file = {
    ".gemini/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/gemini/settings.json";
    ".gemini/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/CLAUDE.md";
    ".gemini/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".gemini/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
  };

}
