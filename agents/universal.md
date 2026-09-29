# Universal Agent Rules

These rules apply to coding agents on this user's machines. `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.gemini/AGENTS.md` use them. Repository rules belong in that repository's `AGENTS.md` and take precedence.

## Agent Configuration

- Change managed agent configuration in `~/.dotfiles`, not in generated home-directory files or Nix store links.

## Documents

- Prefer Org mode (`.org`) for personal writing that the user reads in Emacs, including notes, plans, RFCs, reports, investigations, and drafts.
- Use Markdown (`.md`) for documents intended for a repository, team, or external readers, unless local instructions require another format.
- Keep formats and filenames required by tools, such as `README.md`, `AGENTS.md`, `CLAUDE.md`, and `SKILL.md`.

## Diagrams

- Draw diagrams in D2, not Mermaid. Use Mermaid only where the target renders nothing else, such as a GitHub pull request or issue body.
- In Org, write a named block, `#+begin_src d2 :file <name>.svg :cache yes`, that holds structure only. Emacs prepends `~/.dotfiles/d2/style.d2` when it renders the block, so do not put style in a document.
- Prefer one top-to-bottom flow for a diagram in a document.
- Commit the rendered SVG next to the document, and link it under `#+RESULTS:`, because GitHub renders neither D2 nor a diagram in Org.
- To render outside Emacs, prepend the same style: `cat ~/.dotfiles/d2/style.d2 <name>.d2 | d2 - <name>.svg`.


- Use "Melbourne Baldove" when code author attribution is required.
- Do not add code comments. Use names, small functions, types, and tests to make code clear. Keep existing comments unless the code contradicts them. Tool directives, shebangs, and license identifiers are allowed.

## Computer Use

- Complete routine, reversible UI steps for an authorized task, including authentication and ordinary consent screens.
- When a CLI login uses OAuth, run the CLI login command, complete the browser sign-in and callback with Computer Use, verify that the CLI is authenticated, and continue the task. Do not stop at the browser handoff or ask the user to complete routine OAuth steps that Computer Use can perform.
- If a login flow fails, diagnose it and try available supported routes before asking the user for input.
- Get user confirmation before a payment, financial trade, material legal agreement, destructive deletion, irreversible security or account-recovery change, new access grant, or unrequested external publication or message.
