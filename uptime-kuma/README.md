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
docker network create --internal kuma-db
```

The `--internal` flag on `kuma-db` blocks all internet egress for MariaDB — it
only needs to talk to the kuma container, never the outside world.

### 2. Configure Environment

Copy and edit the environment file:

```bash
cp .env.example .env
nano .env
```

Set these values:
- `MARIADB_ROOT_PASSWORD` — MariaDB root password
- `UPTIME_KUMA_DB_NAME` — Application database name
- `UPTIME_KUMA_DB_USERNAME` — Non-root DB user (created automatically by the MariaDB image)
- `UPTIME_KUMA_DB_PASSWORD` — Non-root DB user password
- `TZ` — Container timezone (optional, defaults to `Europe/Bratislava`)

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
| `MARIADB_ROOT_PASSWORD` | MariaDB root password | Yes |
| `UPTIME_KUMA_DB_NAME` | Application database name | Yes |
| `UPTIME_KUMA_DB_USERNAME` | Non-root DB user (least privilege) | Yes |
| `UPTIME_KUMA_DB_PASSWORD` | Non-root DB user password | Yes |
| `TZ` | Container timezone | No (default: `Europe/Bratislava`) |

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
| `./data` | Uptime Kuma application data |
| `./db` | MariaDB data directory (`/var/lib/mysql` inside the container) |

> **Migrating from a previous LSIO MariaDB setup?**
> The old image stored data under `./config` in LSIO's layout, which isn't readable by the official MariaDB image. Either dump first and re-import:
> ```bash
> docker exec mariadb mysqldump -u root -p"$MARIADB_ROOT_PASSWORD" \
>   "$UPTIME_KUMA_DB_NAME" > uptime-kuma.sql
> # ... swap stacks, then on the new MariaDB:
> docker exec -i uptime-kuma-mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" \
>   "$UPTIME_KUMA_DB_NAME" < uptime-kuma.sql
> ```
> ...or start fresh if you don't need historical monitor data.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` on both containers, minimal `cap_add` | No SYS_ADMIN, NET_ADMIN, etc. |
| Privileges | `security_opt: no-new-privileges` | Setuid binaries cannot gain caps |
| IPC | `ipc: private` | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids` limits via `deploy.resources` | Fork-bomb resistance |
| Memory / CPU | `memory` & `cpus` limits | One service can't starve the others |
| Network | `kuma-db` created with `--internal` | MariaDB has no internet egress |
| Port exposure | `127.0.0.1:3008:3001` | Only the reverse proxy can reach kuma |
| DB user | `MARIADB_USER` / `MARIADB_PASSWORD` (non-root) | App connects with least privilege |
| Healthchecks | Built-in image scripts only | No credentials on the command line |
| Ephemeral writes | `tmpfs` for `/tmp` and `/run/mysqld` | Nothing survives container restart |

> **ICMP ping monitor:** the kuma container has `cap_add: NET_RAW` so the
> built-in ping monitor works. If you only use HTTP/TCP/DNS/Push monitors,
> remove that cap for a stricter baseline.

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