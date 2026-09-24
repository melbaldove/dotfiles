{
  config, pkgs, inputs, ...
}:
{
  home.packages = [
    pkgs.claude-code
  ];

  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
  };

  home.shellAliases = {
    claude = "${pkgs.claude-code}/bin/claude --dangerously-skip-permissions";
  };

  # Claude AI assistant configurations
  home.file = {
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/CLAUDE.md";
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/settings.json";
    ".claude/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
    ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    ".agents/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/agents/skills";

    # Codex agents configuration
    ".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/codex/AGENTS.md";
  };
}
