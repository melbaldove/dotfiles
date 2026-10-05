{ pkgs, ... }:
let
  claudeSwap = pkgs.python313Packages.buildPythonApplication {
    pname = "claude-swap";
    version = "0.26.0";
    pyproject = true;
    src = pkgs.fetchPypi {
      pname = "claude_swap";
      version = "0.26.0";
      hash = "sha256-9H8BPvYnXzYKYAAPWGT1VpfWK7a0gxAMTfcpbkaoSdc=";
    };
    build-system = [ pkgs.python313Packages.hatchling ];
    dependencies = with pkgs.python313Packages; [ textual truststore ];
    doCheck = false;
    meta = {
      description = "Switch saved Claude Code subscription accounts";
      homepage = "https://github.com/realiti4/claude-swap";
      license = pkgs.lib.licenses.mit;
      mainProgram = "cswap";
    };
  };
  accountPython = pkgs.python313.withPackages (python: [ python.websockets ]);
  codexSharedLogin = pkgs.writeShellApplication {
    name = "codex-shared-login";
    text = ''
      unset CODEX_HOME OPENAI_API_KEY CODEX_API_KEY
      if [ "$#" -eq 0 ]; then
        set -- login
      fi
      exec ${accountPython}/bin/python ${../../scripts/codex-shared-login.py} "$@"
    '';
  };
  claudeShared = pkgs.writeShellApplication {
    name = "cc-shared";
    text = ''
      unset CLAUDE_CONFIG_DIR CLAUDE_SECURESTORAGE_CONFIG_DIR
      unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN
      unset ANTHROPIC_PROFILE CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
      exec ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
    '';
  };
  codexShared = pkgs.writeShellApplication {
    name = "codex-shared";
    text = ''
      unset CODEX_HOME OPENAI_API_KEY CODEX_API_KEY
      for argument in "$@"; do
        case "$argument" in
          --remote|--remote=*|--no-daemon)
            echo "codex-shared selects the shared server; transport overrides are not supported." >&2
            exit 2
            ;;
        esac
      done
      has_directory=false
      for argument in "$@"; do
        case "$argument" in
          --)
            break
            ;;
          -C|-C?*|--cd|--cd=*)
            has_directory=true
            ;;
        esac
      done
      if [ "$has_directory" = false ]; then
        set -- --cd "$PWD" "$@"
      fi
      codex app-server daemon start
      endpoint="$(${codexSharedLogin}/bin/codex-shared-login endpoint)"
      exec codex --remote "$endpoint" "$@"
    '';
  };
  agentAccounts = pkgs.writeShellApplication {
    name = "agent-accounts";
    text = ''
      unset CLAUDE_CONFIG_DIR CLAUDE_SECURESTORAGE_CONFIG_DIR
      unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN
      unset ANTHROPIC_PROFILE CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
      case "''${1:-}" in
        "")
          exec ${claudeSwap}/bin/cswap
          ;;
        claude)
          shift
          if [ "$#" -gt 1 ] || [[ "''${1:-}" == -* ]]; then
            echo "Usage: agent-accounts claude [saved-account]" >&2
            exit 2
          fi
          exec ${claudeSwap}/bin/cswap switch "$@"
          ;;
        codex)
          shift
          exec ${codexSharedLogin}/bin/codex-shared-login "$@"
          ;;
        help|-h|--help)
          echo "Usage: agent-accounts [claude [saved-account] | codex [login|status]]"
          echo "Claude switches the shared saved login; Codex signs in once on the shared server."
          ;;
        *)
          echo "Usage: agent-accounts [claude [saved-account] | codex [login|status]]" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [ claudeSwap claudeShared codexShared codexSharedLogin agentAccounts ];
}
