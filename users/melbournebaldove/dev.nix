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
  # Codex releases faster than nixpkgs. Use OpenAI's latest stable release.
  codexUpdater = pkgs.writeShellApplication {
    name = "update-codex";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      install_dir="${config.home.homeDirectory}/.local/bin"

      mkdir -p "$install_dir"
      export PATH="$install_dir:$PATH"

      curl -fsSL https://chatgpt.com/codex/install.sh \
        | CODEX_INSTALL_DIR="$install_dir" CODEX_NON_INTERACTIVE=1 /bin/sh
    '';
  };
  d2Render = pkgs.writeShellApplication {
    name = "d2-render";
    runtimeInputs = [ pkgs.d2 ];
    text = ''
      if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "usage: d2-render <diagram.d2|-> [output.svg]" >&2
        exit 2
      fi

      input="$1"
      if [ "$input" = "-" ] && [ "$#" -ne 2 ]; then
        echo "d2-render: reading stdin needs an output path" >&2
        exit 2
      fi
      output="''${2:-''${input%.d2}.svg}"

      cat "${config.home.homeDirectory}/.dotfiles/d2/style.d2" "$input" | d2 - "$output"

      if [ -z "''${SSH_CONNECTION:-}" ] && command -v open >/dev/null; then
        open -a Preview "$output"
      else
        echo "Rendered $output; open it from the user's machine"
      fi
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
      d2
      d2Render
      librsvg
      playwright-test
      opencode
      openComputerUse
      codexUpdater
      (pkgs.writeShellScriptBin "qwen-code" ''
        exec ${pkgs.nodejs}/bin/npx @qwen-code/qwen-code@latest "$@"
      '')
      (pkgs.writeShellScriptBin "gemini" ''
        exec ${pkgs.nodejs}/bin/npx https://github.com/google-gemini/gemini-cli "$@"
      '')

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

  launchd.agents.codex-update = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${codexUpdater}/bin/update-codex" ];
      RunAtLoad = true;
      StartCalendarInterval = [
        {
          Hour = 9;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/codex-update.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/codex-update-error.log";
    };
  };

  home.activation.codexPstack = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_bin="${config.home.homeDirectory}/.local/bin/codex"
    if [ -x "$codex_bin" ]; then
      export PATH="${pkgs.git}/bin:$PATH"
      run "$codex_bin" plugin marketplace add michael-denyer/pstack-claude \
        && run "$codex_bin" plugin add pstack@pstack-claude \
        || warnEcho "Could not install the pstack Codex plugin"
    else
      warnEcho "Codex is not installed; skipping the pstack Codex plugin"
    fi
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
    ".gemini/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".gemini/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
  };

}
