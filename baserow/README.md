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

### 1. Configure Environment

Copy and edit the environment file:

```bash
cp .env.example .env
nano .env
```

Update these values:
- `POSTGRES_USER` / `POSTGRES_PASSWORD` — Database root credentials
- `POSTGRES_NON_ROOT_USER` / `POSTGRES_NON_ROOT_PASSWORD` — Application database user

### 2. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name
- Update `BASEROW_PUBLIC_URL` to your domain

### 3. Deploy

```bash
docker compose up -d
```

### 4. Access Baserow

Navigate to your configured domain and create an account.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | PostgreSQL root username | `changeUser` |
| `POSTGRES_PASSWORD` | PostgreSQL root password | `changePassword` |
| `POSTGRES_DB` | Database name | `baserow` |
| `POSTGRES_NON_ROOT_USER` | Application DB username | `changeUser` |
| `POSTGRES_NON_ROOT_PASSWORD` | Application DB password | `changePassword` |
| `BASEROW_PUBLIC_URL` | Public URL for Baserow | (required) |

### Reverse Proxy (Caddy)

```
baserow.example.com {
    reverse_proxy http://localhost:89
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 89 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./db_storage` | PostgreSQL data |
| `./baserow_data` | Baserow application data |

## Support the Project

- ☁️ [Baserow Cloud](https://baserow.io/pricing) — Managed hosting
- ⭐ [Star on GitHub](https://github.com/bram2w/baserow)
- 💬 [Join Community](https://community.baserow.io/)

## License

Baserow is released under the [MIT License](https://github.com/bram2w/baserow/blob/develop/LICENSE).