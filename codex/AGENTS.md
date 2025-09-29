# Tooling

- Find files: `fd`
- Find text: `rg` (ripgrep)
- Find code structure:
  - TypeScript `.ts`: `ast-grep --lang ts -p '<pattern>'`
  - TypeScript React `.tsx`: `ast-grep --lang tsx -p '<pattern>'`
  - Other languages: pick the appropriate `--lang`
- Select among matches: pipe results to `fzf`
- JSON processing: `jq`
- YAML/XML processing: `yq`

# Code Style & Comments

- Comment on high-level intent—purpose, design rationale, domain logic.
- Skip comments on straightforward or self-evident code.
- For complex flows, use step comments (e.g., `// (1) parse input`, `// (2) validate data`).
- When deleting code, do not leave "deleted" placeholder comments.

# Git Workflow

- Never amend existing commits.
- Use short, semantic commit messages (one sentence).
- Work on semantic branches (e.g., `feature/auth-login`, `fix/user-permissions`).

# Scope & Clarifications

- Do not expand scope beyond the explicit request; ask before adding safeguards or refactors.
- If requirements feel underspecified or multiple reasonable approaches exist, ask the user to clarify before proceeding.

# Planning & Validation

- Use the planning tool for multi-step or non-trivial tasks; skip it only for obvious, single-edit changes.
- Run relevant tests or checks before committing when feasible. If you cannot run them, clearly explain why and note any manual validation performed.

# Repo Hygiene

- Check the working tree before starting changes to avoid overwriting user edits.
- Surface unexpected modifications immediately instead of continuing blindly.

# Documentation Parity

- When behaviour changes (new endpoints, response tweaks, etc.), update or create the corresponding documentation, examples, or API requests in the same pass.

# Cross-Cutting Topics

- Capture repo-wide knowledge (shared auth, feature flags, deployment, etc.) in `docs/cross-cutting/`. Keep summaries here and link to detailed docs.
- Reference these cross-cutting notes from local guides when they apply, rather than duplicating content.

# Scoped Guides

- Every directory must include a local `AGENTS.md`, even if the workflow is standard. Treat it as an overlay on top of the global rules.
- Each local guide should demonstrate a real understanding of that directory. Cover the sections that make sense—module intent, key entry points, commands or scripts, dependencies and integrations, testing approach, pitfalls, links to deeper docs, and for UI areas, user flows and invariants.
- Keep prose concise but substantive—aim for a one-page onboarding brief, linking out to long-form docs instead of duplicating them.
- Update the relevant local guide in the same PR whenever workflows change, and include an “Updated YYYY-MM-DD” note so staleness is obvious. Highlight open questions if behaviour is unclear and ask for clarification rather than guessing.
- Local guidance can refine or tighten global rules but must not contradict them. If you spot a conflict, record it under “Open Questions” and escalate to the user.
