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

    # Global rules for every agent; CLAUDE.md imports this file
    ".agents/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/agents/AGENTS.md";

    # Codex has no import syntax, so its file is the global rules plus the Codex-only rules
    ".codex/AGENTS.md".source = pkgs.concatText "AGENTS.md" [
      "${inputs.self}/agents/AGENTS.md"
      "${inputs.self}/codex/AGENTS.md"
    ];
  };
}
