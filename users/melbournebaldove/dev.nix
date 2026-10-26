{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  herdr =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "herdr";
        version = "0.9.3";
        src = pkgs.fetchurl {
          url = "https://github.com/herdrdev/herdr/releases/download/v${finalAttrs.version}/herdr-macos-${pkgs.stdenv.hostPlatform.parsed.cpu.name}";
          hash = {
            aarch64-darwin = "sha256-UXOj4K5C1dGrfr+l1eYyn3w9I/jho2d8fOMjHaKIQVc=";
            x86_64-darwin = "sha256-22LVSP8+gysIepaxiUoI0mvjkF8YMDCc1VZ4PyFdQFQ=";
          }.${pkgs.stdenv.hostPlatform.system};
        };
        dontUnpack = true;
        dontBuild = true;
        dontFixup = true;
        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/herdr"
          runHook postInstall
        '';
        meta.mainProgram = "herdr";
      })
    else
      pkgs.herdr or null;
  herdrGpui = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "herdr-gpui";
    version = "20261005.1";
    src = pkgs.fetchurl {
      url = "https://github.com/penso/herdr-gpui/releases/download/v${finalAttrs.version}/herdr-gpui-${finalAttrs.version}-macos-universal.app.tar.gz";
      hash = "sha256-Cu8C3fnpAQ9dLGLORXFRNY13yvMsk6Ny/hbbMg9M0cg=";
    };
    sourceRoot = ".";
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications" "$out/bin"
      cp -R Herdr.app "$out/Applications/"
      ln -s "$out/Applications/Herdr.app/Contents/MacOS/Herdr" "$out/bin/herdr-gpui"
      runHook postInstall
    '';
    meta = {
      mainProgram = "herdr-gpui";
      platforms = lib.platforms.darwin;
    };
  });
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
  # OpenCode 2 releases faster than nixpkgs. Use the official installer.
  opencodeUpdater = pkgs.writeShellApplication {
    name = "update-opencode";
    runtimeInputs = [ pkgs.curl pkgs.gnutar ];
    text = ''
      export PATH="${config.home.homeDirectory}/.opencode/bin:$PATH"
      curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
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
  airshipMcp = pkgs.writeShellApplication {
    name = "airship-mcp";
    runtimeInputs = [ pkgs.uv ];
    text = ''
      keychain() {
        /usr/bin/security find-generic-password -s "$1" -w
      }

      AIRSHIP_APP_KEY="''${AIRSHIP_APP_KEY:-$(keychain AIRSHIP_APP_KEY)}"
      AIRSHIP_CLIENT_ID="''${AIRSHIP_CLIENT_ID:-$(keychain AIRSHIP_CLIENT_ID)}"
      AIRSHIP_CLIENT_SECRET="''${AIRSHIP_CLIENT_SECRET:-$(keychain AIRSHIP_CLIENT_SECRET)}"
      AIRSHIP_REGION="''${AIRSHIP_REGION:-us}"
      export AIRSHIP_APP_KEY AIRSHIP_CLIENT_ID AIRSHIP_CLIENT_SECRET AIRSHIP_REGION

      exec uvx --from "git+https://github.com/urbanairship/agent-tools@1.2.0" airship-mcp
    '';
  };
  airshipMcpReadOnlyGuard = pkgs.writeShellApplication {
    name = "airship-mcp-read-only-guard";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      jq -c '
        def read_only_tools: [
          "start", "list_skills", "get_skill",
          "lookup_channel", "get_channel_tags", "get_channel_attributes",
          "lookup_named_user", "list_segments", "get_segment_info"
        ];
        (.tool_name | sub("^mcp__airship__"; "")) as $tool
        | (.tool_input.method | if type == "string" then ascii_upcase else "" end) as $method
        | if (read_only_tools | index($tool)) != null then empty
          elif $tool == "call_airship_api" and $method == "GET" then empty
          else {
            hookSpecificOutput: {
              hookEventName: "PreToolUse",
              permissionDecision: "deny",
              permissionDecisionReason: "Airship access is read-only: only GET calls and lookup tools are allowed."
            }
          }
          end
      ' || {
        echo "Airship read-only guard failed, so the call is denied." >&2
        exit 2
      }
    '';
  };
in
{
  imports = [
    ./agent-accounts.nix
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
      airshipMcp
      airshipMcpReadOnlyGuard
      librsvg
      playwright-test
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
    ++ lib.optional (herdr != null) herdr
    ++ lib.optionals pkgs.stdenv.isDarwin [
      herdrGpui
      # go-ios removed: has Linux dependencies (iproute2) that prevent it from building on Darwin
    ];

  # Shared shell aliases to keep dev shortcuts consistent across shells
  home.shellAliases = {
    sg = "ast-grep";
  };

  home.activation.herdrGpui = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "copyApps" ] ''
      run ${pkgs.coreutils}/bin/chmod a-w \
        "${config.home.homeDirectory}/Applications/Home Manager Apps/Herdr.app/Contents/MacOS/Herdr"
    ''
  );

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

  launchd.agents.opencode-update = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${opencodeUpdater}/bin/update-opencode" ];
      RunAtLoad = true;
      StartCalendarInterval = [
        {
          Hour = 9;
          Minute = 15;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/opencode-update.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/opencode-update-error.log";
    };
  };

  home.activation.codexMstack = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_bin="${config.home.homeDirectory}/.local/bin/codex"
    if [ -x "$codex_bin" ]; then
      export PATH="${pkgs.git}/bin:$PATH"
      if "$codex_bin" plugin marketplace list 2>/dev/null | grep -q '^pstack-claude '; then
        run "$codex_bin" plugin remove pstack@pstack-claude || true
        run "$codex_bin" plugin marketplace remove pstack-claude || true
      fi
      if "$codex_bin" plugin marketplace list 2>/dev/null | grep -q '^mstack '; then
        run "$codex_bin" plugin marketplace upgrade mstack || warnEcho "Could not upgrade the mstack marketplace"
      else
        run "$codex_bin" plugin marketplace add melbaldove/mstack || warnEcho "Could not add the mstack marketplace"
      fi
      run "$codex_bin" plugin add mstack@mstack \
        && run ${pkgs.python3}/bin/python3 -I "${config.home.homeDirectory}/.dotfiles/agents/codex-trust-mstack.py" "$codex_bin" \
        || warnEcho "Could not install or trust the mstack Codex plugin"
    else
      warnEcho "Codex is not installed; skipping the mstack Codex plugin"
    fi
  '';

  home.file.".local/bin/herdr" = lib.mkIf (herdr != null) {
    source = "${herdr}/bin/herdr";
  };

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
