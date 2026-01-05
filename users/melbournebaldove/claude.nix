{
  config, pkgs, inputs, ...
}:
{
  home.packages = with pkgs; [

  ];

  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
  };

  # Claude AI assistant configurations
  home.file = {
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/CLAUDE.md";
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/settings.json";
    ".claude/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
    
    # Codex agents configuration
    ".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/codex/AGENTS.md";
  };
}