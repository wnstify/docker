# Zulip

<p align="center">
  <img src="https://zulip.com/static/images/logo/zulip-icon-circle.svg" alt="Zulip Logo" width="150">
</p>

<p align="center">
  <a href="https://zulip.com/">Website</a> •
  <a href="https://zulip.readthedocs.io/">Documentation</a> •
  <a href="https://github.com/zulip/zulip">GitHub</a> •
  <a href="https://chat.zulip.org/">Community</a>
</p>

---

[Zulip](https://zulip.com/) is an open-source team chat application with a unique threading model. Organize conversations by topic for better async communication — a powerful alternative to Slack.

## Features

- **Topic-Based Threading** — Conversations organized by topic within streams
- **Powerful Search** — Find any message instantly
- **Markdown Support** — Rich formatting, code blocks, LaTeX
- **Integrations** — 100+ integrations (GitHub, Jira, etc.)
- **Mobile Apps** — iOS and Android applications
- **Guest Access** — Invite external collaborators
- **Message Editing** — Edit and delete messages
- **Read Receipts** — Know when messages are read

## Prerequisites

- Docker and Docker Compose
- External Docker networks (see below)
- Reverse proxy (Caddy, Nginx, Traefik)
- Domain name with DNS configured

## Quick Start

### 1. Create Docker Networks

```bash
docker network create zulip
docker network create zulip-db
docker network create zulip-memcached
docker network create zulip-rabbitmq
docker network create zulip-redis
```

### 2. Configure Environment

Copy and edit the environment file:

```bash
cp .env.example .env
nano .env
```

Generate secure passwords:

```bash
# Generate passwords
openssl rand -base64 32  # For each password field
```

Required variables:
- `POSTGRES_PASSWORD` — PostgreSQL password
- `MEMCACHED_PASSWORD` — Memcached password
- `RABBITMQ_DEFAULT_PASS` — RabbitMQ password
- `REDIS_PASSWORD` — Redis password
- `SECRETS_secret_key` — Zulip secret key
- `SECRETS_email_password` — SMTP password (if using email)

### 3. Update Docker Compose

Edit `docker-compose.yml`:
- Set `SETTING_EXTERNAL_HOST` to your domain
- Set `SETTING_ZULIP_ADMINISTRATOR` to admin email
- Configure `LOADBALANCER_IPS` with your reverse proxy IP
- Update email settings as needed

### 4. Deploy

```bash
docker compose up -d
```

### 5. Create Admin Account

```bash
docker exec -it zulip /home/zulip/deployments/current/manage.py createsuperuser
```

### 6. Access Zulip

Navigate to your configured domain and login.

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `POSTGRES_PASSWORD` | PostgreSQL password | Yes |
| `MEMCACHED_PASSWORD` | Memcached password | Yes |
| `RABBITMQ_DEFAULT_PASS` | RabbitMQ password | Yes |
| `REDIS_PASSWORD` | Redis password | Yes |
| `SECRETS_secret_key` | Zulip secret key | Yes |
| `SETTING_EXTERNAL_HOST` | Public domain | Yes |
| `SETTING_ZULIP_ADMINISTRATOR` | Admin email | Yes |
| `LOADBALANCER_IPS` | Reverse proxy IP | Yes |

### Email Configuration

```yaml
SETTING_EMAIL_HOST: "smtp.example.com"
SETTING_EMAIL_HOST_USER: "your-user"
SECRETS_email_password: "your-password"
SETTING_EMAIL_PORT: "587"
SETTING_EMAIL_USE_TLS: "True"
NOREPLY_EMAIL_ADDRESS: "noreply@example.com"
```

### Reverse Proxy (Caddy)

```
chat.example.com {
    reverse_proxy http://localhost:80
}
```

**Note:** Zulip handles HTTPS internally but can work behind a reverse proxy with `http_only: True`.

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 80 | HTTP | Web interface |
| 443 | HTTPS | Web interface (TLS) |
| 25 | SMTP | Incoming email (optional) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./database` | PostgreSQL data |
| `./rabbitmq` | RabbitMQ data |
| `./redis` | Redis data |
| `./zulip-data` | Zulip uploads and data |

## Architecture

This deployment includes:
- **zulip** — Main application server
- **database** — PostgreSQL database
- **memcached** — Session caching
- **rabbitmq** — Message queue
- **redis** — Caching and rate limiting

## Push Notifications

To enable mobile push notifications, uncomment:

```yaml
SETTING_ZULIP_SERVICE_PUSH_NOTIFICATIONS: "True"
```

This uses Zulip's push notification service.

## Backup

Backup these directories:
- `./database` — PostgreSQL data
- `./zulip-data` — Uploads and settings

```bash
# Stop containers before backup
docker compose stop
tar -czvf zulip-backup.tar.gz ./database ./zulip-data
docker compose start
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/zulip/zulip)
- 💵 [Sponsor on GitHub](https://github.com/sponsors/zulip)
- 💬 [Community Chat](https://chat.zulip.org/)
- 📖 [Documentation](https://zulip.readthedocs.io/)

## License

Zulip is released under the [Apache-2.0 License](https://github.com/zulip/zulip/blob/main/LICENSE).