# Hammerspoon Agent Guide
Updated 2025-10-28

## Intent
- Centralize hotkeys, Hyper key behavior, and window management for macOS via Hammerspoon.
- Keep ergonomic app launching bindings in sync with daily tools.

## Key Files
- `init.lua` — single entry point loaded by Hammerspoon; reloads automatically on `.lua` changes.

## Workflows
- Reload config: edit `init.lua`; watcher triggers `hs.reload()` automatically.
- Hyper key (Right ⌘) emits `cmd+ctrl+alt+shift` combos; ensure other tools leave this modifier combination free.

## Testing Changes
- After edits run `hs.reload()` via the console or touch the file and watch for the Hammerspoon menubar notification; verify hotkeys in use.

## Pitfalls
- Prefer `focusExistingOrLaunch` helper when binding Electron apps to avoid duplicate windows.
- Preserve global references (e.g., `hyperKeyTap`) to prevent Lua GC from disabling event taps.

## Open Questions
- None.
