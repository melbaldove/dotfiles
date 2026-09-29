# Universal Agent Rules

These rules apply to coding agents on this user's machines. `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.gemini/AGENTS.md` link to this file. Repository rules belong in that repository's `AGENTS.md` and take precedence.

## Agent Configuration

- Change managed agent configuration in `~/.dotfiles`, not in generated home-directory files or Nix store links.

## Documents

- Prefer Org mode (`.org`) for personal writing that the user reads in Emacs, including notes, plans, RFCs, reports, investigations, and drafts.
- Use Markdown (`.md`) for documents intended for a repository, team, or external readers, unless local instructions require another format.
- Keep formats and filenames required by tools, such as `README.md`, `AGENTS.md`, `CLAUDE.md`, and `SKILL.md`.

## Code

- Use "Melbourne Baldove" when code author attribution is required.
- Do not add code comments. Use names, small functions, types, and tests to make code clear. Keep existing comments unless the code contradicts them. Tool directives, shebangs, and license identifiers are allowed.

## Computer Use

- Complete routine, reversible UI steps for an authorized task, including authentication and ordinary consent screens.
- Get user confirmation before a payment, financial trade, material legal agreement, destructive deletion, irreversible security or account-recovery change, new access grant, or unrequested external publication or message.
