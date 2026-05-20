# Baserow

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/5/57/Baserow_Logo.png" alt="Baserow Logo" width="300">
</p>

<p align="center">
  <a href="https://baserow.io/">Website</a> •
  <a href="https://baserow.io/docs">Documentation</a> •
  <a href="https://github.com/bram2w/baserow">GitHub</a> •
  <a href="https://community.baserow.io/">Community</a>
</p>

---

[Baserow](https://baserow.io/) is an open-source, no-code database platform that enables users to create, manage, and collaborate on databases with ease. A powerful, self-hosted alternative to Airtable.

## Features

- **No-Code Database** — Create databases without writing code
- **Real-Time Collaboration** — Work together with your team
- **REST API** — Full API access for developers
- **Plugins & Extensions** — Extend functionality as needed
- **Self-Hosted** — Complete control over your data
- **Role-Based Access** — Fine-grained permissions

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)

## Quick Start

### 1. Create Docker Networks

Two of three are `--internal` (no internet egress):

```bash
docker network create baserow-front
docker network create --internal baserow-db
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

The `.env.example` file has `openssl` recipes next to each critical
secret. The three that matter most:

- `BASEROW_JWT_SIGNING_KEY` — signs user-session JWTs. Generate with
  `openssl rand -hex 32`. Losing this logs everyone out, but doesn't
  lose data.
- `SECRET_KEY` — Django's per-deployment secret (CSRF, signed cookies).
  `openssl rand -hex 32`.
- `REDIS_PASSWORD` — protects the Redis instance running inside the
  all-in-one container.

Also set `BASEROW_PUBLIC_URL` to the public URL of your reverse proxy
(must match the Caddyfile exactly — Baserow's internal Caddy does
Host-header matching).

### 3. Deploy

```bash
docker compose up -d
```

First boot syncs ~156 templates — give it 2–3 minutes before it goes
healthy.

### 4. Access Baserow

Navigate to your configured domain and create an account.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `POSTGRES_USER` | Postgres superuser (used only for DB init) | Yes |
| `POSTGRES_PASSWORD` | Postgres superuser password | Yes |
| `POSTGRES_DB` | Database name (default: `baserow`) | Yes |
| `POSTGRES_NON_ROOT_USER` | Baserow's DB user (least privilege) | Yes |
| `POSTGRES_NON_ROOT_PASSWORD` | Baserow DB user password | Yes |
| `BASEROW_JWT_SIGNING_KEY` | 32-byte hex — signs user JWTs | Yes |
| `SECRET_KEY` | 32-byte hex — Django secret for CSRF/cookies | Yes |
| `REDIS_PASSWORD` | Internal Redis password | Yes |
| `BASEROW_PUBLIC_URL` | Public URL (no trailing slash) | Yes |
| `PUID` / `PGID` | Host UID/GID that should own `/baserow/data` | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

### Reverse Proxy (Caddy)

A ready-to-go `Caddyfile` is in this directory. Minimal version:

```
baserow.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:89 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

The proxy `Host` header **must** match `BASEROW_PUBLIC_URL` — Baserow's
internal Caddy uses host-based routing.

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 89 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./db_storage` | PostgreSQL data (`/var/lib/postgresql/data`) |
| `./baserow_data` | Baserow app data: uploads, plugins, internal Redis dump, Caddy state |

> **Upgrading from postgres:17 to postgres:18.4?**
> The compose now uses postgres:18.4, and Postgres 18 changed its default
> data directory. We set `PGDATA=/var/lib/postgresql/data` in the compose
> so existing volumes keep working without migration. Just `docker compose
> pull && docker compose up -d` should be enough.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` (postgres adds 5 init caps; baserow adds 5: NET_BIND_SERVICE for Caddy port 80 + CHOWN/SETUID/SETGID/DAC_OVERRIDE for the s6-overlay+bind-mount init) | No NET_*/SYS_* beyond what's strictly needed |
| Privileges | `security_opt: no-new-privileges` on all containers | Setuid binaries cannot gain caps |
| IPC | `ipc: private` on all containers | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` (pg) / `500` (baserow) | Caps fork sprawl |
| Two-network split | `baserow-db` created with `--internal` | Postgres has no internet egress |
| Port exposure | `127.0.0.1:89` only | Only the reverse proxy can reach Baserow |
| DB user | Baserow connects via `POSTGRES_NON_ROOT_USER` from `init-data.sh` | App never has Postgres superuser |
| Postgres auth | `SCRAM-SHA-256` (`POSTGRES_HOST_AUTH_METHOD`) | Stronger than the default md5 |
| Healthchecks | Built-in image scripts only | No credentials on the command line |
| Process model | s6-overlay drops workers to `baserow`/`redis` users | Long-running processes are non-root |

> **Postgres image upgrade (optional):** swap `postgres:18.4` for
> `dhi.io/postgres:18` (Docker Hardened Images) for a distroless base
> with faster CVE patches. Requires a DHI subscription. Same env vars
> and PGDATA layout — drop-in compatible.

## Support the Project

- ☁️ [Baserow Cloud](https://baserow.io/pricing) — Managed hosting
- ⭐ [Star on GitHub](https://github.com/bram2w/baserow)
- 💬 [Join Community](https://community.baserow.io/)

## License

Baserow is released under the [MIT License](https://github.com/bram2w/baserow/blob/develop/LICENSE).