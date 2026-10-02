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
- Render every diagram you draw, and show it to the user. Do not leave rendering to the user. Run `d2-render <name>.d2`, which prepends the style, writes `<name>.svg` beside the source, and opens it in Preview. For an Org block, pipe the block body: `d2-render - <name>.svg`.
- Over SSH, `d2-render` does not open the SVG. Send the file with the agent's file-sharing tool if it has one. If it has none, give the user the path.

## Explanations

- Write explanations in plain, controlled English, about 80% of the way to ASD-STE100. Follow **Writing Replies**.
- Choose the format that makes the subject easiest to understand, not the one that is fastest to write. Text suits a short answer. Draw a D2 diagram for structure, flow, or relationships. Build a single-file HTML page for something the user will explore, compare, or come back to, such as a system, a data set, or a set of trade-offs.
- Treat these as throwaway artifacts. Build them when they make the subject easier to understand, even if they will never be reused.
- Offer a narrated explainer video only when the user asks for one, or when motion is essential to the idea. Video needs API keys or heavy local compute.

## Writing Replies

- Answer the question the user asked, in the user's terms. If the user asks for a version, give the version number, not a package label. Do not open with "Yes" or "No" when it answers a narrower question.
- Put the answer first. If the user must decide, approve, or act, put that first as a command, then give the reason. Do not put a request or a warning after a long report, a code block, or a list of steps.
- Repeat a pending user action in each status update until the user does it. Say plainly when the work waits on the user.
- Give each thing one name and use it every time. If two things can share a name, qualify each use, for example "the local copy of the SageMaker files" and "the live SageMaker host", or "`main` in hy-agents".
- Before you use a label that you made, such as a script, a check, a status, or a component name, say in one clause what it is. Define domain and vendor terms the first time they appear in the conversation. Do not define common engineering terms such as PR, CI, SHA, or SSH.
- Say who did each action, for example "I deleted", "a previous session wrote", or "you approved". This matters most for changes to files, hosts, and secrets.
- When you report a gap, name the actor and the next step, for example "I have not checked the live stream. I can check it now." Do not write "it could not be verified".
- Say what each check covered. If you did not verify something, say so at the start of the reply. In a list of results, give each item one subject, so that an untested item does not hide in a passed item.
- State the scope of a change near the start: what changed, where, and what did not change. Keep the lines that say what you checked and what you did not check.
- Give only the information the user needs now. Do not repeat advice or a reminder after the user declines it.
- Write full sentences. Do not use telegraphic headings as rules or instructions. Do not stack more than three nouns, such as "analytics MCP cutoff check".
- Use one numbered list per reply for questions or options, so that a reply like "1. yes" has one meaning. Use letters or bullets for other lists.
- Give the reason for each conclusion or recommendation, with "because". When you compare options, give the same measure for each option.
- When the user asks why, explain the decision in plain words first. Add file names, config keys, and line numbers after that, if they help.
- Put a condition before the instruction that depends on it, for example "If you are remote, ...".
- Use tables and lists for data. Use connected sentences with "because", "so", and "but" for reasoning.
- Put answers in the final reply. Do not leave them only in an interim progress message.
- Keep a tense when it carries meaning, such as "has been exposed since 2021" or "the copy is still running". Do not apply sentence-length limits to table cells.

## Code

- Use "Melbourne Baldove" when code author attribution is required.
- Do not add code comments. Use names, small functions, types, and tests to make code clear. Keep existing comments unless the code contradicts them. Tool directives, shebangs, and license identifiers are allowed.

## Computer Use

- Complete routine, reversible UI steps for an authorized task, including authentication and ordinary consent screens.
- When a CLI login uses OAuth, run the CLI login command, complete the browser sign-in and callback with Computer Use, verify that the CLI is authenticated, and continue the task. Do not stop at the browser handoff or ask the user to complete routine OAuth steps that Computer Use can perform.
- If a login flow fails, diagnose it and try available supported routes before asking the user for input.
- Get user confirmation before a payment, financial trade, material legal agreement, destructive deletion, irreversible security or account-recovery change, new access grant, or unrequested external publication or message.
