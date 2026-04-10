# MeshCentral RMM — Hardened Docker Deployment

Self-hosted remote monitoring and management (RMM) platform using [MeshCentral](https://meshcentral.com) with [Docker Hardened Images](https://dhi.io) for MongoDB.

Supports remote desktop, terminal, file transfer, and Intel AMT management across Linux, Windows, and macOS — all from a web browser.

## Architecture

```
Internet
  |
Pangolin (TLS termination)
  |
127.0.0.1:4430 (HTTPS)
  |
[mc-frontend] ── MeshCentral (Node.js, port 443)
                       |
                 [mc-internal] ── MongoDB 8.0 (DHI, port 27017)
```

Agents and the web UI share port 443 — everything goes through Pangolin.

### Services

| Service | Image | Purpose |
|---------|-------|---------|
| **meshcentral** | `ghcr.io/ylianst/meshcentral:latest-mongodb` | RMM web server + agent hub |
| **mongodb** | `dhi.io/mongodb:8.0-debian13` | Database (Docker Hardened Image, zero CVEs) |

### Ports

| Port | Binding | Purpose |
|------|---------|---------|
| 4430/tcp | `127.0.0.1` | HTTPS web UI + agent connections (reverse proxy target) |

## Quick Start

```bash
# 1. Generate configuration
./generate-config.sh rmm.yourdomain.com

# 2. Deploy
docker compose up -d

# 3. Point Pangolin to https://127.0.0.1:4430 (skip TLS verify — self-signed internal cert)

# 4. Visit https://rmm.yourdomain.com and create your admin account
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
