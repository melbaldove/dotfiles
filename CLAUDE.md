# CLAUDE.md

Personal dotfiles. Nix flake configuration for multi-machine management.

## Structure
```
hosts/         # Machine configs (turing, einstein, shannon, newton)
modules/       # System configs
  system/      # shared/, darwin/, linux/
users/         # User configs (melbournebaldove/)
secrets/       # Encrypted with agenix
```

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

# Linux
deploy .            # Deploy all
deploy .#shannon    # Deploy specific

# Secrets
agenix -e secrets/secret-name.age  # Edit secret
agenix -r                          # Re-key all secrets

# Maintenance
nix flake update
deploy --dry-activate .#<host>
```

## Services
- Grafana: `http://shannon:3000`
- Prometheus: `http://shannon:9090`
- Loki: `http://shannon:3100`
- AlertManager: `http://shannon:9093`
- Twenty CRM: `https://crm.workwithnextdesk.com`
- Ghost CMS: `https://cms.workwithnextdesk.com`
- Outline Wiki: `https://wiki.workwithnextdesk.com`
- n8n: `https://n8n.workwithnextdesk.com`

## Network
- Personal VPN: 10.0.0.0/24 (shannon:1, einstein:2, turing:3, phone:4)
- Startup VPN: 10.0.1.0/24 (shannon:1, newton:2)

## Adding Services
1. Create module in `modules/system/linux/`
2. Add secrets to `secrets/secrets.nix`
3. Import in host config
4. Configure firewall rules

## Monitoring
- Prometheus scrapes metrics from all hosts via VPN
- Loki aggregates logs from promtail agents
- Grafana dashboards available on shannon
- AlertManager sends notifications to Slack

## Deployment
- Whenever a deployment fails, it rollback. Any new configuration will be undoed