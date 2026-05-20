# Authentik

<p align="center">
  <img src="https://goauthentik.io/img/icon_left_brand.svg" alt="Authentik Logo" width="400">
</p>

<p align="center">
  <a href="https://goauthentik.io/">Website</a> •
  <a href="https://docs.goauthentik.io/">Documentation</a> •
  <a href="https://github.com/goauthentik/authentik">GitHub</a> •
  <a href="https://goauthentik.io/discord/">Discord</a>
</p>

---

[Authentik](https://goauthentik.io/) is an open-source identity provider offering modern, flexible, and secure authentication and authorization. Single sign-on, MFA, OAuth2/OIDC/SAML/LDAP/SCIM, custom flows — fully self-hostable.

## Features

- **Single Sign-On (SSO)** — Centralized authentication for all your applications
- **Multiple Protocols** — OAuth2, OIDC, SAML, LDAP, RADIUS, and SCIM support
- **Multi-Factor Authentication** — TOTP, WebAuthn, Duo, SMS, static codes
- **User Management** — Intuitive interface for users, groups, and permissions
- **Customizable Flows** — Build custom authentication workflows
- **Self-Hosted** — Full control over your identity infrastructure

## Prerequisites

- Docker and Docker Compose
- Two external Docker networks (`authentik-front`, `authentik-db`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS

## Quick Start

### 1. Create Docker Networks

One of two is `--internal` (no internet egress for postgres/redis):

```bash
docker network create authentik-front
docker network create --internal authentik-db
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

The `.env.example` file has `openssl` recipes next to each critical secret. The three that matter most:

- `PG_PASS` — postgres password. Generate with `openssl rand -base64 36 | tr -d '\n'`.
- `REDIS_PASSWORD` — redis password (defense in depth — redis is already on an internal-only network). Same generator.
- `AUTHENTIK_SECRET_KEY` — signs session cookies. Generate with `openssl rand -base64 60 | tr -d '\n'`. **Losing this invalidates all sessions; leaking it lets attackers forge them.**

Set `PUID`/`PGID` to your host UID/GID (`id` will tell you). All four containers run as this user — no root in any container.

### 3. Create Data Directories

```bash
mkdir -p data/{database,redis,media,certs,custom-templates}
```

### 4. Deploy

```bash
docker compose up -d
```

First boot runs Django migrations (~30–60 s). The server reports healthy via the built-in `ak healthcheck`.

### 5. Initial Setup

Two options:

- **Interactive**: visit `https://your-domain/if/flow/initial-setup/` and create your admin account in the browser.
- **Bootstrap (env-driven)**: set `AUTHENTIK_BOOTSTRAP_EMAIL`, `AUTHENTIK_BOOTSTRAP_PASSWORD`, and `AUTHENTIK_BOOTSTRAP_TOKEN` in `.env` before first start — the `akadmin` user is created automatically and you skip the interactive flow.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `PG_USER` | Postgres user / owner of the authentik DB | Yes (default `authentik`) |
| `PG_PASS` | Postgres password | Yes |
| `PG_DB` | Database name | Yes (default `authentik`) |
| `REDIS_PASSWORD` | Redis password (also enforced by `--requirepass`) | Yes |
| `AUTHENTIK_SECRET_KEY` | Session cookie signing key | Yes |
| `AUTHENTIK_ERROR_REPORTING__ENABLED` | Sentry error reporting | No (default `false`) |
| `COMPOSE_PORT_HTTP` / `COMPOSE_PORT_HTTPS` | Host port bindings (127.0.0.1) | No (defaults 9000/9443) |
| `AUTHENTIK_EMAIL__*` | SMTP settings — host/port/user/pass/from | No |
| `AUTHENTIK_BOOTSTRAP_*` | First-boot admin credentials | No |
| `PUID` / `PGID` | Host UID/GID for all containers | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

### Reverse Proxy (Caddy)

Authentik publishes both an HTTP listener (port 9000) and an HTTPS listener (9443). For a Caddy-fronted deployment, target the HTTP listener and let Caddy handle TLS:

```caddyfile
auth.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:9000
}
```

If you want end-to-end TLS (Caddy → authentik), target the HTTPS listener with `tls_insecure_skip_verify` (authentik uses a self-signed internal cert).

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 9000 | HTTP | Web interface (reverse-proxy target) |
| 9443 | HTTPS | Web interface, TLS (optional E2E TLS target) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data/database` | PostgreSQL data |
| `./data/redis` | Redis snapshots (sessions, celery queue) |
| `./data/media` | User-uploaded media (avatars, branding assets) |
| `./data/certs` | TLS certs for SAML/RADIUS providers (worker manages) |
| `./data/custom-templates` | Custom email/flow templates |

> **Upgrading from postgres:17 to postgres:18.4?**
> The compose pins `PGDATA=/var/lib/postgresql/data` so existing volumes
> keep working without migration. Just `docker compose pull && docker
> compose up -d`.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` on all four services, **zero `cap_add`** (verified by test, May 2026) | No Linux capabilities granted to any container |
| Non-root | All containers run as `${PUID}:${PGID}` (default 1000) | No root in any container — postgres, redis, server, worker all UID 1000 |
| Privileges | `security_opt: no-new-privileges` on all containers | Setuid binaries cannot gain caps |
| IPC | `ipc: private` on all containers | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` (pg) / `100` (redis) / `500` (server) / `500` (worker) | Caps fork sprawl |
| Two-network split | `authentik-db` created with `--internal` | Postgres + Redis have no internet egress, no host ports |
| Port exposure | `127.0.0.1` only on 9000/9443 | Only the reverse proxy can reach authentik |
| Postgres auth | `SCRAM-SHA-256` (`POSTGRES_HOST_AUTH_METHOD`) | Stronger than the default md5 |
| Redis auth | `--requirepass` + `AUTHENTIK_REDIS__PASSWORD` | Defense in depth even on an internal-only network |
| Docker socket | **NOT mounted** on the worker (upstream default mounts it as root) | Worker cannot escape to host — see below for outpost integration |
| Healthchecks | `ak healthcheck` (server/worker), `pg_isready` (postgres), `redis-cli ping` (redis) | Startup gated via `depends_on: service_healthy` |

### Optional Upgrade — Docker Outposts

Authentik can auto-deploy proxy / LDAP / RADIUS *outposts* as Docker containers if the worker has access to `/var/run/docker.sock`. The hardened default removes this mount — the worker container cannot escape to the host.

If you need Docker outposts, the **safer pattern** is a docker-socket-proxy in front of the real socket:

```yaml
services:
  docker-socket-proxy:
    image: tecnativa/docker-socket-proxy:0.3.0
    environment:
      CONTAINERS: 1
      IMAGES: 1
      NETWORKS: 1
      POST: 1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks: [authentik-db]
    # ... cap_drop, no-new-privileges, etc.

  worker:
    environment:
      AUTHENTIK_OUTPOSTS__CONTAINER_IMAGE_BASE: ghcr.io/goauthentik/%(type)s:%(version)s
      DOCKER_HOST: tcp://docker-socket-proxy:2375
```

This restricts the worker to a narrow Docker API surface (no `RUN`, no socket access, no host root). If you want the upstream "mount the host socket directly" pattern, add `/var/run/docker.sock:/var/run/docker.sock` to the worker volumes and accept that a worker compromise becomes a host root compromise.

### Optional Upgrade — Non-Root Postgres User

This template uses a single `PG_USER` that owns the authentik database (matching upstream). Switching to a separate superuser-for-init / non-root-for-app model would add complexity *and* risk breaking future authentik migrations that may need `CREATE EXTENSION` privileges. Authentik never exposes the DB to anything else, so the single-user model is fine here.

## Support the Project

- ⭐ [Star on GitHub](https://github.com/goauthentik/authentik)
- 💬 [Join Discord](https://goauthentik.io/discord/)
- 💵 [Sponsor Development](https://github.com/sponsors/goauthentik)
- 🎟️ [Enterprise License](https://goauthentik.io/pricing/)

## License

Authentik is released under the [MIT License](https://github.com/goauthentik/authentik/blob/main/LICENSE).
