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

- Amending existing commits require an explicit override from the user. NEVER amend commits on your own.
- Use short, semantic commit messages (one sentence) e.g. (feat:, fix:, docs: etc)
- Work on semantic branches (e.g., `feature/auth-login`, `fix/user-permissions`).

# NO GAMBIARRA POLICY - ASK FOR FEEDBACK INSTEAD

Due to the difficulty of implementing this codebase, we must strive to keep the code high quality, clean, modular, simple and functional - more like an Agda codebase, less like a C codebase. Gambiarras, hacks and duct taping must be COMPLETELY AVOIDED, in favor of robust, simple and general solutions.

In some cases, you will be asked to perform a seemingly impossible task, either because it is (and the user is unaware), or because you don't grasp how to do it properly. In these cases, DO NOT ATTEMPT TO IMPLEMENT A HALF-BAKED SOLUTION JUST TO SATISFY THE USER'S REQUEST. If the task seems too hard, be honest that you couldn't solve it in the proper way, leave the code unchanged, explain the situation to the user and ask for further feedback and clarifications.

The user is a domain expert that will be able to assist you in these cases.

## Planning, Proving Completeness & Correctness
- For diagnostics: Demonstrate that you inspected the actual code by citing file paths and relevant excerpts; tie the root cause to the implementation.
- For implementations: Provide evidence for dependency installation and all required checks (linting, type checking, tests, build). Resolve all controllable failures.
- Think in invariants. Always reason from the properties that must remain true across all states and code paths. Each change, branch, or handler must preserve these truths; if an invariant breaks, the bug’s already there—no need to chase symptoms.

# Repo Hygiene

- Check the working tree before starting changes to avoid overwriting user edits.
- If there is unrelated code in the working tree, assume the user or another agent is working on them. DO NOT MODIFY. If unable to proceed, stop and clarify.

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

# Debugging
- When inspecting the code is not fruitful lean towards debugging with the user by adding prefixed debug logs.

## Following Repository Conventions
- Match existing code style, patterns, and naming.
- Review similar modules before adding new ones.
- Respect framework/library choices already present.
- Avoid superfluous documentation; keep changes consistent with repo standards.
- Implement the changes in the simplest way possible.

# Asking questions
List questions at the very bottom in a numbered list so user can refer to them
