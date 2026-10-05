{
  config, pkgs, inputs, lib, osConfig, ...
}:
let
  agentInstructions = builtins.readFile ../../agents/universal.md
    + lib.optionalString (osConfig.networking.hostName == "eisenhower") ''

      ## Host Context

      - This agent runs on Eisenhower. Assume the user is operating this host through a remote connection.
  '';
in
{
  home.packages = [
    pkgs.claude-code
  ];

  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
  };

  # Claude AI assistant configurations
  home.file = {
    ".claude/CLAUDE.md".text = agentInstructions;
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/settings.json";
    ".claude/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
    ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    ".claude-sphere/CLAUDE.md".text = agentInstructions;
    ".claude-sphere/commands".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/commands";
    ".claude-sphere/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/claude/settings.json";
    ".claude-sphere/shared".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/claude/shared";
    ".claude-sphere/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    ".agents/skills".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/agents/skills";

    ".codex/AGENTS.md".text = agentInstructions;
    ".gemini/AGENTS.md".text = agentInstructions;
  };
}
