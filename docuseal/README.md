# DocuSeal

<p align="center">
  <img src="https://www.docuseal.com/logo.svg" alt="DocuSeal Logo" width="300">
</p>

<p align="center">
  <a href="https://www.docuseal.com/">Website</a> •
  <a href="https://www.docuseal.com/docs">Documentation</a> •
  <a href="https://github.com/docusealco/docuseal">GitHub</a>
</p>

---

[DocuSeal](https://www.docuseal.com/) is an open-source document signing platform — create, fill, and sign digital documents. A self-hosted alternative to DocuSign and HelloSign.

This template uses the **free open-source** `docuseal/docuseal` image from Docker Hub — no paid dashboard or license key required.

## Features

- **Document Templates** — Create reusable document templates
- **Digital Signatures** — Legally binding electronic signatures
- **Form Fields** — Text, signature, date, checkbox, and more
- **PDF Support** — Upload and process PDF documents (PDF rendering bundled inside the image)
- **API Access** — Integrate with your applications
- **Self-Hosted** — Full control over sensitive documents

## Prerequisites

- Docker and Docker Compose
- Two external Docker networks (`docuseal-front`, `docuseal-db`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS

## Quick Start

### 1. Create Docker Networks

One of two is `--internal` (no internet egress for postgres):

```bash
docker network create docuseal-front
docker network create --internal docuseal-db
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

The `.env.example` file has `openssl` recipes next to each critical secret. The three that matter most:

- `POSTGRES_PASSWORD` — postgres superuser password (used only for init). Generate with `openssl rand -base64 36 | tr -d '\n'`.
- `POSTGRES_NON_ROOT_PASSWORD` — the password the DocuSeal app actually uses to connect. Same generator.
- `SECRET_KEY_BASE` — Rails secret. Generate with `openssl rand -hex 64`. **Losing this invalidates all sessions; leaking it lets attackers forge them.**

Set `FORCE_SSL` to your public HTTPS URL (it must match what your reverse proxy serves). Set `PUID`/`PGID` to your host UID/GID (`id` will tell you).

### 3. Create Data Directories

```bash
mkdir -p data/{app,db}
```

### 4. Deploy

```bash
docker compose up -d
```

First boot runs Rails migrations (~30–60 s). The app reports healthy via Rails' built-in `/up` endpoint.

### 5. First Login

Visit `https://docuseal.example.com` and create your admin account on first run.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `POSTGRES_USER` | Postgres superuser (init only) | Yes |
| `POSTGRES_PASSWORD` | Postgres superuser password | Yes |
| `POSTGRES_DB` | Database name | Yes (default `docuseal`) |
| `POSTGRES_NON_ROOT_USER` | DocuSeal's DB user (least privilege) | Yes |
| `POSTGRES_NON_ROOT_PASSWORD` | DocuSeal DB user password | Yes |
| `SECRET_KEY_BASE` | Rails secret (128 hex chars) | Yes |
| `FORCE_SSL` | Public HTTPS URL | Yes |
| `DOCUSEAL_PORT` | Host port (127.0.0.1 only) | No (default 3000) |
| `SMTP_*` | Outbound email settings | No |
| `PUID` / `PGID` | Host UID/GID for postgres | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

### Reverse Proxy (Caddy)

```caddyfile
docuseal.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:3000
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 3000 | HTTP | Web interface (reverse-proxy target) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data/db` | PostgreSQL data |
| `./data/app` | DocuSeal documents, uploads, and bundled Redis snapshots |

> **Upgrading from postgres:17 to postgres:18.4?**
> The compose pins `PGDATA=/var/lib/postgresql/data` so existing volumes
> keep working without migration. Just `docker compose pull && docker
> compose up -d`.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` on both services, **zero `cap_add`** (verified by test, May 2026) | No Linux capabilities granted to any container |
| Privileges | `security_opt: no-new-privileges` on both containers | Setuid binaries cannot gain caps |
| IPC | `ipc: private` on both containers | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` (pg) / `500` (app) | Caps fork sprawl |
| Two-network split | `docuseal-db` created with `--internal` | Postgres has no internet egress, no host ports |
| Port exposure | `127.0.0.1` only on 3000 | Only the reverse proxy can reach DocuSeal |
| DB user | App connects via `POSTGRES_NON_ROOT_USER` from `init-data.sh` | App never has Postgres superuser |
| Postgres auth | `SCRAM-SHA-256` (`POSTGRES_HOST_AUTH_METHOD`) | Stronger than the default md5 |
| Healthchecks | Rails `/up` (app), `pg_isready` (postgres) | Startup gated via `depends_on: service_healthy` |
| Non-root postgres | Postgres runs as `${PUID}:${PGID}` | No root in the database container |
| Bundled services | Redis + PDF rendering are inside the app image, not separate containers | Fewer attack surfaces, no extra secrets, no extra networks |

## Architecture

This deployment is exactly two containers:

- **docuseal-app** — the Rails app, Sidekiq workers, bundled Redis, and the bundled PDF processing pipeline (replaces the old separate Gotenberg sidecar).
- **docuseal-postgres** — PostgreSQL 18 database, internal-only network.

## Support the Project

- ☁️ [DocuSeal Cloud](https://www.docuseal.com/pricing) — Managed hosting
- ⭐ [Star on GitHub](https://github.com/docusealco/docuseal)
- 📖 [Documentation](https://www.docuseal.com/docs)

## License

DocuSeal is released under the [AGPL-3.0 License](https://github.com/docusealco/docuseal/blob/master/LICENSE).
