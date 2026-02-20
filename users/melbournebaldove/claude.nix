{
  config, pkgs, inputs, ...
}:
{
  home.packages = [
    (pkgs.writeShellScriptBin "claude-code" ''
      exec ${pkgs.nodejs}/bin/npx @anthropic-ai/claude-code@latest "$@"
    '')
  ];

  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
  };

  home.shellAliases = {
    claude = "claude-code --dangerously-skip-permissions";
  };

  # Claude AI assistant configurations
  home.file = {
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/CLAUDE.md";
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/settings.json";
    ".claude/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
    ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/skills";

    # Codex agents configuration
    ".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/codex/AGENTS.md";
  };
}