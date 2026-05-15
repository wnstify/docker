# Dockhand

<p align="center">
  <a href="https://dockhand.pro/">Website</a> &bull;
  <a href="https://dockhand.pro/docs">Documentation</a> &bull;
  <a href="https://github.com/Finsys/dockhand">GitHub</a>
</p>

---

[Dockhand](https://dockhand.pro/) is a modern, security-focused Docker management UI. A self-hosted alternative to Portainer with free SSO/OIDC, zero telemetry, vulnerability scanning, and a visual Compose editor with Git integration.

## Features

- **Container Management** -- Start, stop, restart, remove with real-time CPU/memory monitoring
- **Compose Editor** -- Visual Docker Compose editor with Git integration and webhook deployments
- **Web Terminal** -- Interactive terminal and file browser (no SSH needed)
- **Vulnerability Scanning** -- Grype/Trivy integration scans images before auto-updates
- **Multi-Environment** -- Local socket, remote TCP+TLS, and Hawser agent for NAT/firewall traversal
- **SSO/OIDC & MFA** -- Free on all tiers (no SSO tax)
- **Zero Telemetry** -- No cloud dependencies, fully self-contained

## Architecture

3 containers across 3 isolated Docker networks:

```
Internet
  |
Reverse Proxy (TLS termination)
  |
127.0.0.1:3000
  |
[dockhand-frontend] -- Dockhand (web UI + API)
  |                        |
[dockhand-database]    [dockhand-socket]
  |                        |
PostgreSQL            Socket Proxy
                          |
                    /var/run/docker.sock (read-only)
```

### Services

| Service | Image | Purpose |
|---------|-------|---------|
| **dockhand** | `fnsys/dockhand:latest` | Web UI, REST API, container management |
| **postgresql** | `postgres:alpine` | Primary database |
| **socket-proxy** | `tecnativa/docker-socket-proxy:0.3` | Filtered Docker socket access |

### Network Segmentation

| Network | Type | Purpose |
|---------|------|---------|
| `dockhand-frontend` | bridge | External access (localhost-bound) |
| `dockhand-database` | internal | PostgreSQL communication only |
| `dockhand-socket` | internal | Docker socket proxy communication only |

## Prerequisites

- Docker and Docker Compose
- Reverse proxy (Caddy, Nginx Proxy Manager, Traefik) for HTTPS termination

## Quick Start

### 1. Create Data Directories

```bash
mkdir -p database data
sudo chown -R 1000:1000 database data
```

### 2. Configure Environment

Copy and edit the environment file:

```bash
cp example.env .env
nano .env
```

Generate a strong password for `PG_PASS`:

```bash
openssl rand -hex 32
```

### 3. Deploy

```bash
docker compose up -d
```

### 4. Initial Setup

Navigate to your configured domain and create an admin account. The first account becomes the instance owner.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PG_USER` | PostgreSQL username | `dockhand` |
| `PG_PASS` | PostgreSQL password | (required) |
| `PG_DB` | Database name | `dockhand` |

### Reverse Proxy (Caddy)

```
dockhand.example.com {
    reverse_proxy http://localhost:3000
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 3000 | HTTP | Web interface & API |

## Data Persistence

| Path | Description |
|------|-------------|
| `./database` | PostgreSQL data |
| `./data` | Dockhand application data (stacks, git repos, encryption keys) |

## Security Hardening

This template includes comprehensive security measures:

| Feature | Description |
|---------|-------------|
| `cap_drop: ALL` | All Linux capabilities dropped by default |
| `no-new-privileges:true` | Prevents privilege escalation |
| `ipc: private` | Isolated IPC namespace |
| `user: 1000:1000` | Non-root container execution |
| Resource limits | CPU, memory, and PID limits on all containers |
| Docker socket proxy | Filtered API access (never exposes the raw socket to Dockhand) |
| Internal networks | Database and socket traffic cannot reach the internet |
| Health checks | All services monitored with startup grace periods |
| Log rotation | JSON file driver with 10 MB / 3 file limits |

## Backup

```bash
# Stop the stack
docker compose down

# Backup database and app data
tar -czvf dockhand-backup-$(date +%Y%m%d).tar.gz database data .env

# Restart
docker compose up -d
```

## Support the Project

- [Dockhand Website](https://dockhand.pro/)
- [GitHub](https://github.com/Finsys/dockhand)
- [Documentation](https://dockhand.pro/docs)

## License

Dockhand is released under the [Business Source License 1.1](https://github.com/Finsys/dockhand/blob/main/LICENSE) (BSL-1.1). Free for personal use, internal business use, non-profits, education, and evaluation. Auto-converts to Apache 2.0 on January 1, 2029.
