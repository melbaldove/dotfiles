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
    cc = "CLAUDE_CONFIG_DIR=${config.home.homeDirectory}/.claude ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions";
    cc-sphere = "CLAUDE_CONFIG_DIR=${config.home.homeDirectory}/.claude-sphere ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions";
  };

  # Claude AI assistant configurations
  home.file = {
    # One universal rules file for every agent; each link gives it the name its tool reads
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/agents/universal.md";
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/settings.json";
    ".claude/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
    ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    ".claude-sphere/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/agents/universal.md";
    ".claude-sphere/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".claude-sphere/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/settings.json";
    ".claude-sphere/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
    ".claude-sphere/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    ".agents/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/agents/skills";

    ".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/agents/universal.md";
  };
}
