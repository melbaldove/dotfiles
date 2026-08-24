# AGENTS.md

Personal dotfiles. Nix flake configuration for multi-machine management.

## Git Workflow

Work only on `main`. Do not create or switch to another branch or worktree unless the user explicitly asks.

After each verified requested change, automatically commit and push the relevant files to `origin/main`. Do not include unrelated user changes. Skip the commit or push only when the user explicitly asks.

## Computer Use

When Computer Use is available on the host, use it proactively for routine,
reversible steps that complete an already authorized task. Keep the user out of
the loop when the action is safe and within the requested task. This includes
authentication flows into an already authorized account, SSO browser approval,
login callbacks, ordinary consent screens, permission prompts that are
necessary for the requested task, UI navigation, and similar setup work. The
default is to complete these steps autonomously instead of asking the user to
click a button that the agent can safely click.

This policy does not expand the task scope. Do not use Computer Use for a
materially destructive or high-impact action without user confirmation. Ask
for confirmation before making a payment or purchase, placing a financial
trade, accepting material legal terms, deleting data destructively, making an
irreversible security or account-recovery change, granting access beyond the
requested scope, or publishing or sending content externally when that action
was not already requested. Apply the same boundary to similar consequential
actions.

Routine authentication into an account that the task already authorizes is
different from privilege escalation or a new access grant. The first may be
completed autonomously when it is routine and reversible. The second requires
user confirmation unless the requested task explicitly includes that specific
change.

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
