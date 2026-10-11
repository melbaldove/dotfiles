# Personal Superset MCP

`superset-mcp.toml` owns the personal Superset entry for Codex.
The entry uses the workspace Nix shell and the admitted full-upgrade proxy.
The launcher opens an authenticated SSM tunnel to the candidate host on port 5008.
It closes the tunnel when the proxy exits.
The signing key stays in the existing private local state directory.

Apply the source entry from the workspace Nix shell.

```sh
uv run --python python3 python ~/.dotfiles/scripts/install-superset-mcp.py
```

The installer preserves all other Codex settings and saves the original configuration outside Git.
It refuses to replace a different existing Superset entry.
Refresh the Codex MCP configuration or start a new chat after installation.
Run `just aws-reauth` from the workspace if the selected AWS profile expires.
