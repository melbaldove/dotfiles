# AGENTS.md

Personal dotfiles. Nix flake configuration for multi-machine management.

## Git Workflow

Work only on `main`. Do not create or switch to another branch or worktree unless the user explicitly asks.

After each verified requested change, automatically commit and push the relevant files to `origin/main`. Do not include unrelated user changes. Skip the commit or push only when the user explicitly asks.

## Structure
```
hosts/         # Darwin host configs (turing, eisenhower)
modules/       # Shared Darwin system configs
users/         # User configs (melbournebaldove/)
```

Server configuration lives in `/Users/melbournebaldove/nix-infra`.

## Finding Files
**IMPORTANT: Use `tree` for file discovery. DON'T use `find` for simple name matching - use `tree` instead.**

```bash
tree -L 2                    # Project overview
tree modules/system/linux/   # Linux modules
tree hosts/                  # Host configs
tree users/                  # User configs
tree -P '*.nix' --prune      # All .nix files
```

## Commands
```bash
# macOS
sudo darwin-rebuild switch --flake .#turing

# Maintenance
nix flake update
```

## Remote Access

- Tailscale supplies private connectivity between hosts.
- OpenSSH authenticates SSH sessions with the declared Ed25519 keys.
- `ssh einstein` and `ssh eisenhower` use their Tailscale MagicDNS names.
- LAN SSH remains available for local recovery.
