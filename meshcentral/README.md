# MeshCentral RMM — Hardened Docker Deployment

Self-hosted remote monitoring and management (RMM) platform using [MeshCentral](https://meshcentral.com) with a hardened compose baseline (capability-dropped, network-segmented, resource-limited).

Supports remote desktop, terminal, file transfer, and Intel AMT management across Linux, Windows, and macOS — all from a web browser.

## Architecture

```
Browsers ── Internet ── Pangolin (TLS) ── 127.0.0.1:4430
                                              |
                                        [mc-frontend] ── MeshCentral (Node.js, port 443)
                                              |               |
Agents ── Tailscale (WireGuard) ──────────────┘         [mc-internal] ── MongoDB 8.0
```

**Standard mode**: Agents and web UI both go through Pangolin on port 443.

**Tailscale mode**: Web UI goes through Pangolin, agents connect directly via Tailscale IP — private, WireGuard encrypted, no public exposure for agent traffic. MeshCentral certs are generated for the Tailscale IP with WANonly mode enabled.

### Services

| Service | Image | Purpose |
|---------|-------|---------|
| **meshcentral** | `ghcr.io/ylianst/meshcentral:1.1.59-mongodb` | RMM web server + agent hub |
| **mongodb** | `mongo:8.0.23` | Database (official Docker image, internal network only) |

> **Optional upgrade — Docker Hardened Images:** if you have a [Docker
> Hardened Images](https://dhi.io) subscription, swap `mongo:8.0.23` for
> `dhi.io/mongodb:8.0-debian13` for a distroless runtime with faster CVE
> patches. Same env vars and `/data/db` layout — drop-in replacement.
> The shell-based healthcheck (`mongosh`) will need to be disabled since
> the DHI runtime has no shell; MeshCentral's healthcheck still covers
> full-stack health.

### Ports

| Port | Binding | Purpose |
|------|---------|---------|
| 4430/tcp | `127.0.0.1` | HTTPS web UI + agent connections (reverse proxy target) |

## Quick Start

```bash
# Standard — agents connect via domain through Pangolin
./generate-config.sh rmm.yourdomain.com

# Or with Tailscale — agents connect via Tailscale IP directly
./generate-config.sh rmm.yourdomain.com --tailscale 100.x.x.x

# Deploy
docker compose up -d

# Point Pangolin to https://127.0.0.1:4430 (skip TLS verify — self-signed internal cert)
# Visit https://rmm.yourdomain.com and create your admin account
# Then set "newAccounts": false in data/meshcentral-data/config.json
```

## Files

```
meshcentral/
  docker-compose.yml      # Hardened Docker Compose
  generate-config.sh      # Config + secret generator
  README.md               # This file
  USAGE.md                # Operations guide
  SECURITY.md             # Security documentation
```

Generated at deploy time (not committed):
```
  .env                                    # Compose variables (chmod 600)
  data/meshcentral-data/config.json       # MeshCentral configuration
  data/meshcentral-data/                  # Certs, keys, config
  data/meshcentral-files/                 # User uploaded files
  data/meshcentral-backups/               # Automated backups
  data/mongodb/                           # Database files
```

## Acknowledgements

❤️ Thanks to [Ylian Saint-Hilaire](https://github.com/Ylianst) and all MeshCentral contributors for building a truly open-source RMM platform. Thanks to [Docker](https://docker.com) and [MongoDB](https://mongodb.com) for making hardened, production-ready images freely available.

## Managed Hosting

Don't want to manage this yourself? [Webnestify](https://webnestify.cloud) offers fully managed, hardened self-hosted deployments — MeshCentral, AI tools, and more — on dedicated infrastructure with monitoring, backups, and ongoing maintenance included.
