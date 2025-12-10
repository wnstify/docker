# Uptime Kuma

<p align="center">
  <img src="https://uptime.kuma.pet/img/icon.svg" alt="Uptime Kuma Logo" width="150">
</p>

<p align="center">
  <a href="https://uptime.kuma.pet/">Website</a> •
  <a href="https://github.com/louislam/uptime-kuma/wiki">Wiki</a> •
  <a href="https://github.com/louislam/uptime-kuma">GitHub</a>
</p>

---

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is a self-hosted monitoring tool for tracking uptime of websites, APIs, and services. Beautiful UI, multiple notification channels, and status pages.

## Features

- **Multiple Monitor Types** — HTTP(s), TCP, Ping, DNS, and more
- **Status Pages** — Public status pages for your services
- **Notifications** — 90+ notification services (Telegram, Discord, Slack, Email...)
- **Beautiful UI** — Modern, responsive dashboard
- **Multi-Language** — Available in 30+ languages
- **Certificate Monitoring** — SSL certificate expiry alerts
- **Maintenance Windows** — Scheduled maintenance periods

## Prerequisites

- Docker and Docker Compose
- External Docker networks (`kuma`, `kuma-db`)
- Reverse proxy (Caddy, Nginx, Traefik)

## Quick Start

### 1. Create Docker Networks

```bash
docker network create kuma
docker network create kuma-db
```

### 2. Configure Environment

Copy and edit the environment file:

```bash
cp .env.example .env
nano .env
```

Set these values:
- `UPTIME_KUMA_DB_NAME` — Database name
- `UPTIME_KUMA_DB_USERNAME` — Database username
- `UPTIME_KUMA_DB_PASSWORD` — Database password
- `MYSQL_ROOT_PASSWORD` — MariaDB root password

### 3. Deploy

```bash
docker compose up -d
```

### 4. Initial Setup

1. Access Uptime Kuma at `http://your-server:3008`
2. Create an admin account
3. Start adding monitors

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `UPTIME_KUMA_DB_NAME` | Database name | Yes |
| `UPTIME_KUMA_DB_USERNAME` | Database username | Yes |
| `UPTIME_KUMA_DB_PASSWORD` | Database password | Yes |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password | Yes |
| `PUID` | User ID for file permissions | No |
| `PGID` | Group ID for file permissions | No |

### Reverse Proxy (Caddy)

```
status.example.com {
    reverse_proxy http://localhost:3008
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 3008 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | Uptime Kuma data (SQLite mode) |
| `./config` | MariaDB configuration |

## Monitor Types

| Type | Description |
|------|-------------|
| HTTP(s) | Website availability and response time |
| TCP Port | Port connectivity check |
| Ping | ICMP ping monitoring |
| DNS | DNS resolution check |
| Push | Heartbeat monitoring (cron jobs, etc.) |
| Steam Game Server | Game server status |
| Docker Container | Container health via Docker socket |

## Setting Up Notifications

1. Go to **Settings** → **Notifications**
2. Click **Setup Notification**
3. Choose your service (Telegram, Discord, Email, etc.)
4. Configure credentials and test

### Popular Notification Services

- **Telegram**: Create a bot via @BotFather
- **Discord**: Create a webhook in channel settings
- **Email**: Use SMTP credentials
- **Slack**: Create an incoming webhook

## Status Pages

1. Go to **Status Pages**
2. Click **New Status Page**
3. Add monitors to display
4. Share the public URL

## Support the Project

- ⭐ [Star on GitHub](https://github.com/louislam/uptime-kuma)
- 💵 [Sponsor on GitHub](https://github.com/sponsors/louislam)
- 💵 [Open Collective](https://opencollective.com/uptime-kuma)
- 🐛 [Report Issues](https://github.com/louislam/uptime-kuma/issues)

## License

Uptime Kuma is released under the [MIT License](https://github.com/louislam/uptime-kuma/blob/master/LICENSE).