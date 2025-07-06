# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles managed with Nix. Uses a flake-based, modular configuration for multi-machine and multi-OS system management with comprehensive infrastructure services including monitoring, VPN, CRM, and CMS.

## Repository Structure

### Root Directory
```
.dotfiles/
├── flake.nix              # Main flake configuration
├── flake.lock             # Flake dependency lock file
├── CLAUDE.md              # This file - Claude Code instructions
├── README.md              # Repository overview
├── .envrc                 # Direnv configuration
├── .gitignore             # Git ignore patterns
├── claude/                # Claude-specific configuration files
├── docs/                  # Documentation
├── emacs/                 # Emacs configuration files
├── gemini/                # Gemini CLI configuration
├── ghostty/               # Ghostty terminal configuration
├── git/                   # Git configuration
├── hammerspoon/           # Hammerspoon (macOS) configuration
├── nushell/               # Nushell configuration
├── network/               # Network configuration files
├── templates/             # Project templates
└── tmp/                   # Temporary files
```

### Core Configuration Directories

#### `hosts/` - Machine Configurations
- **`turing/`**: macOS development machine (aarch64-darwin)
  - Primary development workstation with GUI applications
- **`einstein/`**: Linux home server (x86_64-linux)
  - Home lab server with media services
- **`shannon/`**: Linux remote server (x86_64-linux)
  - Remote server with monitoring and VPN gateway
- **`newton/`**: Linux startup server (x86_64-linux)
  - Business applications server (CRM, CMS)

#### `modules/` - System-Level Configurations
- **`system/shared/`**: Cross-platform configurations
  - `core.nix`: Essential packages and settings
  - `ssh-keys.nix`: SSH key management
  - `node-exporter.nix`: Prometheus node exporter
- **`system/darwin/`**: macOS-specific configurations
  - `default.nix`: macOS system defaults
  - `gui.nix`: GUI applications and settings
  - `wireguard-client.nix`: WireGuard client setup
  - `agenix.nix`: Secrets management for macOS
- **`system/linux/`**: Linux-specific configurations
  - `default.nix`: Linux system defaults
  - `monitoring.nix`: Prometheus + Grafana monitoring stack
  - `ghost-cms.nix`: Ghost CMS service configuration
  - `twenty-crm.nix`: Twenty CRM service configuration
  - `media-server.nix`: Media server services
  - `wireguard-server.nix`: WireGuard server configuration
  - `wireguard-gateway.nix`: WireGuard gateway configuration
  - `agenix.nix`: Secrets management for Linux

#### `users/` - User-Specific Configurations
- **`melbournebaldove/`**: Personal user configurations
  - `core.nix`: Base user settings (Git, shell, etc.)
  - `dev.nix`: Development environment (languages, tools)
  - `emacs.nix`: Emacs configuration
  - `desktop.nix`: Desktop environment settings
  - `claude.nix`: Claude-specific user settings

#### `scripts/` - Automation Scripts
- `setup-darwin.sh`: Initial macOS setup script
- `setup-wireguard-agenix-darwin.sh`: WireGuard setup for macOS
- `test-vpn-connectivity.sh`: VPN connectivity testing
- `generate-wireguard-keys.sh`: WireGuard key generation

#### `secrets/` - Encrypted Secrets (agenix)
- `secrets.nix`: Secret definitions and access control
- `*.age`: Encrypted secret files (WireGuard keys, passwords, etc.)

## Architecture Overview

### Network Topology
```
Internet
    │
    ▼
shannon (VPN Server/Gateway)
    │
    ├─ 10.0.0.0/24 (Personal Network)
    │   ├─ shannon: 10.0.0.1 (Monitoring, VPN)
    │   ├─ einstein: 10.0.0.2 (Home Server)
    │   └─ turing: 10.0.0.3 (Development)
    │
    └─ 10.0.1.0/24 (Startup Network)
        └─ newton: 10.0.1.2 (Business Apps)
```

### Service Architecture
- **Monitoring**: Prometheus + Grafana on shannon, collecting from all hosts
- **VPN**: WireGuard mesh network connecting all machines
- **Business Apps**: Twenty CRM + Ghost CMS on newton
- **Secrets**: agenix for encrypted configuration management
- **Deployment**: deploy-rs for remote Linux deployments

## Configuration Guidelines

When adding or changing a configuration, use the following guidelines to determine the correct location:

- **`hosts/`**: Use this directory to define a new machine. A host file should not contain any real configuration logic. Its only job is to `import` the necessary modules from `modules/` and `users/` to assemble a complete system.

- **`modules/`**: This is for system-level configuration that can be shared between machines.
  - **`modules/system/shared/`**: For settings that apply to *all* systems (e.g., core packages, Nix settings).
  - **`modules/system/darwin/`**: For settings that only apply to macOS (e.g., Homebrew, macOS defaults).
  - **`modules/system/linux/`**: For settings that only apply to Linux (e.g., filesystem options, bootloader).

- **`users/`**: This is for user-specific configuration (Home Manager settings).
  - **`users/melbournebaldove/core.nix`**: Your base settings that you want on *every* machine (e.g., Git config, shell aliases).
  - **`users/melbournebaldove/dev.nix`**: Settings for your development environment (e.g., Emacs, programming languages).
  - Create new files here to define different roles (e.g., `server.nix` for headless servers).

## Infrastructure Services

### Monitoring Stack
- **Prometheus**: Metrics collection (port 9090) on shannon
- **Grafana**: Visualization dashboard (port 3000) on shannon
- **Node Exporter**: System metrics (port 9100) on all hosts
- **cAdvisor**: Container metrics (port 9200) on newton

### VPN Network
- **WireGuard Server**: shannon acts as central VPN gateway
- **Dual Networks**: Personal (10.0.0.0/24) and Startup (10.0.1.0/24)
- **Cross-Platform**: Clients on macOS (turing) and Linux servers

### Business Applications
- **Twenty CRM**: Modern CRM system on newton:3000
- **Ghost CMS**: Publishing platform on newton:8080
- **Docker Compose**: Services managed via Arion/Docker Compose

### Available Hosts

- **`turing`**: macOS development machine (aarch64-darwin)
- **`einstein`**: Linux home server (x86_64-linux)
- **`shannon`**: Linux remote server (x86_64-linux)
- **`newton`**: Linux startup server (x86_64-linux)

## Development Commands

### System Management
```bash
# Rebuild the 'turing' macOS system configuration
sudo darwin-rebuild switch --flake .#turing

# Deploy to 'einstein' NixOS home server remotely
deploy --remote-build --skip-checks --hostname einstein .#einstein

# Deploy to 'shannon' remote server
deploy --remote-build --skip-checks --hostname shannon .#shannon

# Deploy to 'newton' startup server
deploy --remote-build --skip-checks --hostname newton .#newton

# Dry run deployment (test without applying changes)
deploy --dry-activate --remote-build --skip-checks --hostname einstein .#einstein
deploy --dry-activate --remote-build --skip-checks --hostname shannon .#shannon

# Update dependencies
nix flake update

# Initial macOS setup (run once)
./scripts/setup-darwin.sh
```

### Service Management
```bash
# Test VPN connectivity between all machines
./scripts/test-vpn-connectivity.sh

# Setup WireGuard on macOS with agenix secrets
./scripts/setup-wireguard-agenix-darwin.sh

# Generate new WireGuard keys
./scripts/generate-wireguard-keys.sh
```

### Service URLs
- **Grafana Dashboard**: `http://shannon:3000` (admin/admin)
- **Prometheus**: `http://shannon:9090`
- **Twenty CRM**: `https://crm.workwithnextdesk.com`
- **Ghost CMS**: `https://cms.workwithnextdesk.com`

## Deployment Strategy

This repository uses deploy-rs for remote deployment to Linux systems:

- **Remote building**: Builds happen on the target machine to avoid cross-compilation issues
- **Atomic deployments**: Rollback capability for failed deployments
- **Multi-host support**: Deploy to multiple servers with different configurations
- **Secrets management**: Encrypted secrets deployed securely via agenix

## Secrets Management

- **`secrets/`**: Contains encrypted secrets managed with agenix
- **SSH keys**: Used for both authentication and secret encryption/decryption
- **WireGuard keys**: Managed through agenix for secure VPN configuration
- **Service credentials**: Database passwords, API keys, etc.
- **Access control**: Secrets are only accessible to authorized hosts

## Monitoring and Observability

### Metrics Collection
- **Prometheus**: Centralized metrics storage on shannon
- **Node Exporter**: System metrics from all hosts
- **cAdvisor**: Docker container metrics from newton
- **Custom exporters**: Application-specific metrics

### Visualization
- **Grafana**: Dashboard and alerting platform
- **Pre-configured dashboards**: System overview, container metrics, VPN status
- **Alerting**: Email/Slack notifications for critical issues

### Log Management
- **Systemd journals**: Centralized logging via journald
- **Service logs**: Application logs from CRM and CMS
- **VPN logs**: WireGuard connection and traffic logs

## Security Features

### Network Security
- **WireGuard VPN**: Encrypted mesh network between all hosts
- **Firewall rules**: Restrictive iptables configuration
- **SSH hardening**: Key-based authentication, fail2ban
- **Network segmentation**: Separate networks for personal and business use

### Secrets Management
- **agenix encryption**: Age-based secret encryption
- **Key rotation**: Support for rotating WireGuard and service keys
- **Principle of least privilege**: Secrets only accessible where needed

### Service Security
- **Container isolation**: Docker containers with resource limits
- **Database security**: Encrypted connections, strong passwords
- **TLS termination**: HTTPS for all web services
- **Regular updates**: Automated security updates via Nix

## Backup and Recovery

### Configuration Backup
- **Git repository**: All configuration in version control
- **Flake lock**: Reproducible dependency versions
- **Secrets backup**: Encrypted secrets stored securely

### Data Backup
- **Database backups**: Regular dumps of CRM and CMS data
- **File backups**: User data and uploads
- **Configuration snapshots**: System state preservation

## Troubleshooting

### Common Issues
- **VPN connectivity**: Check WireGuard status and firewall rules
- **Service startup**: Review systemd logs and container status
- **Deployment failures**: Check deploy-rs logs and network connectivity
- **Secret access**: Verify agenix configuration and key availability

### Debugging Commands
```bash
# Check WireGuard status
sudo wg show

# View service logs
journalctl -u servicename -f

# Check container status
docker ps -a

# Test network connectivity
ping -c 4 hostname

# Check deployed configuration
nixos-rebuild dry-run --flake .#hostname
```

## Scripts Reference

- **`scripts/setup-darwin.sh`**: Initial macOS setup script
- **`scripts/setup-wireguard-agenix-darwin.sh`**: WireGuard setup for macOS
- **`scripts/test-vpn-connectivity.sh`**: VPN connectivity testing
- **`scripts/generate-wireguard-keys.sh`**: WireGuard key generation

## Adding New Services

When adding a new service:

1. **Create module**: Add service configuration in `modules/system/linux/`
2. **Define secrets**: Add any required secrets to `secrets/secrets.nix`
3. **Update host**: Import the module in relevant host configuration
4. **Add monitoring**: Include metrics endpoint in Prometheus config
5. **Configure firewall**: Open required ports in host firewall rules
6. **Test deployment**: Use dry-run to verify configuration