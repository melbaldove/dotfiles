{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  tex = (
    pkgs.texlive.combine {
      inherit (pkgs.texlive)
        scheme-basic
        luatex
        fontspec
        xcolor
        mylatexformat
        preview
        dvisvgm
        dvipng # for preview and export as html
        wrapfig
        amsmath
        ulem
        hyperref
        capt-of
        ;
    }
  );

  openComputerUseVersion = "0.3.1";
  openComputerUseSource = pkgs.fetchFromGitHub {
    owner = "iFurySt";
    repo = "open-codex-computer-use";
    rev = "v${openComputerUseVersion}";
    sha256 = "0sv3hvvi7ncwa3q590ai8zlzy4gqbw87ny4q8b19k5s54f458wkv";
  };
  openComputerUse = pkgs.stdenvNoCC.mkDerivation {
    pname = "open-computer-use";
    version = openComputerUseVersion;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/open-computer-use/-/open-computer-use-${openComputerUseVersion}.tgz";
      hash = "sha512-q8gsh6Pqme7qiiLiDXWdsr6xs8TTO0zRaW1e8nEIigEg8uwBurPFp8CWbq8mPuLWxk+5lQqk2Tdq9iICj82WZQ==";
    };
    sourceRoot = "package";
    dontBuild = true;
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications" "$out/bin" "$out/lib/open-computer-use"
      cp -R . "$out/lib/open-computer-use/"
      cp -R "dist/Open Computer Use.app" "$out/Applications/"
      ln -s "$out/Applications/Open Computer Use.app/Contents/MacOS/OpenComputerUse" \
        "$out/bin/open-computer-use"
      ln -s "$out/bin/open-computer-use" "$out/bin/ocu"
      ln -s "$out/bin/open-computer-use" "$out/bin/open-computer-use-mcp"
      ln -s "$out/bin/open-computer-use" "$out/bin/open-codex-computer-use-mcp"

      runHook postInstall
    '';
  };
in
{
  imports = [
    ./claude.nix
    ./openclaw.nix
  ];

  home.packages =
    with pkgs;
    [
      tex
      imagemagick
      gh
      fd
      ripgrep
      ast-grep
      nodejs
      bun
      docker
      nmap
      wireguard-tools
      deploy-rs
      cmake
      libtool
      tree
      fzf
      gleam
      mermaid-cli
      playwright-test
      opencode
      openComputerUse
      (pkgs.writeShellScriptBin "qwen-code" ''
        exec ${pkgs.nodejs}/bin/npx @qwen-code/qwen-code@latest "$@"
      '')
      (pkgs.writeShellScriptBin "gemini" ''
        exec ${pkgs.nodejs}/bin/npx https://github.com/google-gemini/gemini-cli "$@"
      '')

      codex
      inputs.agenix.packages.${pkgs.system}.default
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # go-ios removed: has Linux dependencies (iproute2) that prevent it from building on Darwin
    ];

  # Shared shell aliases to keep dev shortcuts consistent across shells
  home.shellAliases = {
    sg = "ast-grep";
  };

  # Development-specific bash aliases and setup
  programs.bash.bashrcExtra = ''
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
    ".codex/skills/open-computer-use".source = "${openComputerUseSource}/skills/open-computer-use";
    ".gemini/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${inputs.self}/gemini/settings.json";
    ".gemini/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/CLAUDE.md";
    ".gemini/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".gemini/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
  };

}
