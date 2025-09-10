# When you need to call tools from the shell, use this rubric:

- Find Files: `fd`
- Find Text: `rg` (ripgrep)
- Find Code Structure (TS/TSX): `ast-grep`
  - Default to TypeScript:
    - `.ts` → `ast-grep --lang ts -p '<pattern>'`
    - `.tsx` (React) → `ast-grep --lang tsx -p '<pattern>'`
  - For other languages, set `--lang` appropriately (e.g., `--lang rust`).
- Select among matches: pipe to `fzf`
- JSON: `jq`
- YAML/XML: `yq`

## Commenting Guidelines
- Focus on high-level intent: explain why the code exists, key design decisions, and domain logic.
- Skip comments on straightforward or obvious code.
- For moderately to highly complex functions, use step comments (e.g., // (1) parse input, // (2) validate data) to guide readers through the flow.

## Commit Guidelines
- Never commit directly to non-feature branches. Always double-check your branch before committing.
- Use short, semantic commit messages (one sentence). Do not add extended descriptions.
- Create and work on semantic branches (e.g., feature/auth-login, fix/user-permissions).