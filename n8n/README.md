# n8n

<p align="center">
  <img src="https://raw.githubusercontent.com/n8n-io/n8n/master/assets/n8n-logo.png" alt="n8n Logo" width="200">
</p>

<p align="center">
  <a href="https://n8n.io/">Website</a> •
  <a href="https://docs.n8n.io/">Documentation</a> •
  <a href="https://github.com/n8n-io/n8n">GitHub</a> •
  <a href="https://community.n8n.io/">Community</a>
</p>

---

[n8n](https://n8n.io/) is an open-source workflow automation platform. Connect apps, automate tasks, and build complex workflows with a visual editor. A powerful, self-hosted alternative to Zapier and Make.

## Features

- **Visual Workflow Builder** — Drag-and-drop interface
- **400+ Integrations** — Connect to popular services
- **Code When Needed** — JavaScript/Python for custom logic
- **Self-Hosted** — Full control over your data
- **Webhooks** — Trigger workflows from external events
- **Scheduling** — Run workflows on a schedule
- **Error Handling** — Built-in retry and error workflows

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)

## Quick Start

### 1. Create Docker Networks

Two of the three are `--internal` (no internet egress):

```bash
docker network create n8n-front
docker network create --internal n8n-db
docker network create --internal n8n-runners
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

The `.env.example` file lists every required value with `openssl` recipes
for generating the two critical secrets:

- `N8N_ENCRYPTION_KEY` — encrypts saved credentials. **If you lose this
  after saving credentials, those credentials are unrecoverable.**
  Generate with: `openssl rand -hex 32`
- `N8N_RUNNERS_AUTH_TOKEN` — shared between n8n and the task runner.
  Generate with: `openssl rand -base64 32`

Also set `N8N_HOST` and `WEBHOOK_URL` to match your public domain.

### 3. Deploy

```bash
docker compose up -d
```

### 4. Access n8n

Navigate to your configured domain and create an owner account.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `POSTGRES_USER` | Postgres superuser (used only for init) | Yes |
| `POSTGRES_PASSWORD` | Postgres superuser password | Yes |
| `POSTGRES_DB` | Database name (default: `n8n`) | Yes |
| `POSTGRES_NON_ROOT_USER` | n8n DB user (least privilege) | Yes |
| `POSTGRES_NON_ROOT_PASSWORD` | n8n DB user password | Yes |
| `N8N_ENCRYPTION_KEY` | 32-byte hex — encrypts saved credentials | Yes |
| `N8N_RUNNERS_AUTH_TOKEN` | Shared n8n ↔ runner token | Yes |
| `N8N_HOST` | Hostname only (no scheme) | Yes |
| `WEBHOOK_URL` | Full external URL with trailing slash | Yes |
| `TZ` | Container timezone | No (default: `Europe/Bratislava`) |

### Reverse Proxy (Caddy)

```
n8n.example.com {
    reverse_proxy http://localhost:5678
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 5678 | HTTP | n8n editor & webhooks (bound to `127.0.0.1`) |
| 5679 | RPC  | Task-runner broker (internal network only) |
| 5680 | RPC  | Runner health (internal network only) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./db_storage` | PostgreSQL data (`/var/lib/postgresql/data`) |
| `./n8n_storage` | n8n workflows, settings, encrypted credentials |

The runner is stateless — no volume needed.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` (postgres adds 5 init caps; n8n/runner add none) | No NET/SYS caps anywhere |
| Privileges | `security_opt: no-new-privileges` on all containers | Setuid binaries cannot gain caps |
| IPC | `ipc: private` on all containers | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids` 200 / 500 / 300 (pg / n8n / runner) | Caps fork sprawl |
| Memory / CPU | Per-container limits | One service can't starve the others |
| Three-network split | `n8n-db` and `n8n-runners` created with `--internal` | Postgres + runner have no internet egress |
| Port exposure | `127.0.0.1:5678` only | Only the reverse proxy can reach n8n |
| DB user | `POSTGRES_NON_ROOT_USER` (created by `init-data.sh`) | n8n never has Postgres superuser |
| Task runner | Code/Function nodes execute in a separate container | Workflow JavaScript can't touch n8n's process memory |
| Healthchecks | `pg_isready` / `wget` `/healthz` — no creds on cmdline | Built-in scripts only |
| Telemetry | `N8N_DIAGNOSTICS_ENABLED=false` | No phone-home |
| File perms | `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true` | n8n refuses to start if `~/.n8n/config` is world-readable |

> **Code nodes can't make outbound HTTP calls by default** because the
> runner is on an internal network. If a workflow needs external HTTP
> from JavaScript, use n8n's **HTTP Request node** (runs in the n8n
> container, has internet via `n8n-front`). To allow outbound from the
> runner anyway, drop `internal: true` on the `n8n-runners` network.

> **Postgres image upgrade (optional):** swap `postgres:18.4` for
> `dhi.io/postgres:18` (Docker Hardened Images) for a distroless base
> with faster CVE patches. Requires a DHI subscription.

## Email Configuration

To enable email notifications, uncomment and configure the SMTP settings in `docker-compose.yml`:

```yaml
- N8N_EMAIL_MODE=smtp
- N8N_SMTP_HOST=smtp.example.com
- N8N_SMTP_PORT=587
- N8N_SMTP_USER=your-user
- N8N_SMTP_PASS=your-password
- N8N_SMTP_SENDER=n8n@example.com
```

## Support the Project

- ☁️ [n8n Cloud](https://n8n.io/pricing) — Managed hosting
- ⭐ [Star on GitHub](https://github.com/n8n-io/n8n)
- 💬 [Join Community](https://community.n8n.io/)
- 📖 [Documentation](https://docs.n8n.io/)

## License

n8n is released under a [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).