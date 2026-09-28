# Global Agent Rules

These rules apply to every coding agent on this user's machines. Claude Code imports this file from `~/.claude/CLAUDE.md`, and Codex reads it as the first part of `~/.codex/AGENTS.md`.

## Configuration Layer

- `~/.dotfiles` (`github.com/melbaldove/dotfiles`) is the configuration layer for this user's machines. It is a Nix flake with nix-darwin and Home Manager for the hosts `turing` and `eisenhower`.
- It owns the configuration of the shell, terminals, Emacs, and the coding agents: this file, `~/.claude`, `~/.codex`, `~/.gemini`, and the shared skills in `~/.agents/skills`.
- To change a tool's configuration, change it in `~/.dotfiles`, not in the live file in the home directory. Many live files are symlinks into the Nix store, so they are read-only, and the next switch replaces them.
- A file that Home Manager links from the flake source takes effect only after `sudo darwin-rebuild switch --flake ~/.dotfiles#<host>`. The user runs that command. To see how a file is linked, read `users/melbournebaldove/*.nix`.
- Read `~/.dotfiles/AGENTS.md` in full before you edit the repo. It sets its own Git workflow.

## Documents

- Write documents for the user in Org mode (`.org`): notes, plans, reports, investigations, and drafts. The user reads them in Emacs.
- Use Markdown when a tool or a project requires it: `README.md`, `AGENTS.md`, `CLAUDE.md`, `SKILL.md`, pull request and issue text, and any repository whose own conventions use Markdown. A project's convention wins over this rule.
