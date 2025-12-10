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

### 1. Configure Environment

Copy and edit the environment file:

```bash
cp .env.example .env
nano .env
```

Update these values:
- `POSTGRES_USER` / `POSTGRES_PASSWORD` — Database root credentials
- `POSTGRES_NON_ROOT_USER` / `POSTGRES_NON_ROOT_PASSWORD` — n8n database user

### 2. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name
- Update `WEBHOOK_URL` to your public URL
- Update `N8N_HOST` to your domain
- Generate and set `N8N_ENCRYPTION_KEY`
- Update `GENERIC_TIMEZONE` to your timezone

### 3. Generate Encryption Key

```bash
openssl rand -hex 32
```

### 4. Deploy

```bash
docker compose up -d
```

### 5. Access n8n

Navigate to your configured domain and create an owner account.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | PostgreSQL root username | `changeUser` |
| `POSTGRES_PASSWORD` | PostgreSQL root password | `changePassword` |
| `POSTGRES_DB` | Database name | `n8n` |
| `POSTGRES_NON_ROOT_USER` | n8n database username | `changeUser` |
| `POSTGRES_NON_ROOT_PASSWORD` | n8n database password | `changePassword` |
| `WEBHOOK_URL` | Public webhook URL | (required) |
| `N8N_HOST` | n8n hostname | (required) |
| `N8N_ENCRYPTION_KEY` | Encryption key for credentials | (required) |
| `GENERIC_TIMEZONE` | Timezone | `Europe/Bratislava` |

### Reverse Proxy (Caddy)

```
n8n.example.com {
    reverse_proxy http://localhost:5678
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 5678 | HTTP | Web interface & webhooks |

## Data Persistence

| Path | Description |
|------|-------------|
| `./db_storage` | PostgreSQL data |
| `./n8n_storage` | n8n workflows and credentials |

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