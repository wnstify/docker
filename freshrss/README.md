# FreshRSS

<p align="center">
  <img src="https://freshrss.org/images/icon.svg" alt="FreshRSS Logo" width="150">
</p>

<p align="center">
  <a href="https://freshrss.org/">Website</a> •
  <a href="https://freshrss.github.io/FreshRSS/">Documentation</a> •
  <a href="https://github.com/FreshRSS/FreshRSS">GitHub</a>
</p>

---

[FreshRSS](https://freshrss.org/) is a free, self-hosted RSS feed aggregator. Lightweight, fast, and privacy-focused — manage all your feeds in one place.

## Features

- **Fast & Lightweight** — Handles thousands of feeds efficiently
- **Multi-User Support** — Perfect for families or teams
- **API Support** — Google Reader, Fever API for mobile apps
- **Customizable** — Themes, extensions, and layouts
- **Keyboard Shortcuts** — Power-user friendly
- **Mobile Responsive** — Works on any device

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)

## Quick Start

### 1. Create the Docker network

```bash
docker network create freshrss
```

### 2. Configure environment

```bash
cp .env.example .env
nano .env
```

Set `TZ` to your timezone. `CRON_MIN` controls the built-in feed refresh
schedule (default: minutes `3,33` past every hour).

### 3. Deploy

```bash
docker compose up -d
```

### 4. Initial Setup

1. Access FreshRSS at `http://your-server:88` (or via your reverse proxy)
2. Follow the installation wizard — select **SQLite** as the database type
3. Create your admin account
4. Start adding RSS feeds

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TZ` | Container timezone | `Europe/Bratislava` |
| `CRON_MIN` | Built-in feed-refresh cron schedule (minute field). Empty string disables internal cron. | `3,33` |
| `TRUSTED_PROXY` | Networks whose `X-Forwarded-*` headers FreshRSS trusts. Set in compose to `127.0.0.0/8 172.16.0.0/12 192.168.0.0/16 10.0.0.0/8`. | — |

The upstream image runs Apache as the non-root `apache` user (UID 82) by
default — there are no `PUID`/`PGID` env vars to set (that's an LSIO
convention not used here). If you need the host data dir owned by your
own UID, add a `user:` directive to the compose and pre-`chown` the
`./data` directory yourself.

### Reverse Proxy (Caddy)

A ready-to-go `Caddyfile` is in this directory. Minimal version:

```
rss.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:88 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

The compose already sets `TRUSTED_PROXY` to RFC1918 ranges so FreshRSS
trusts these headers when they come from a Docker-network proxy.

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 88 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | FreshRSS config, per-user SQLite databases, per-user logs |
| `./extensions` | Installed extensions (optional — uncomment in compose to enable) |

> **Migrating from the previous LSIO-based template?**
> The old container mounted `${PWD}/fresh-rss → /config` in LSIO's layout.
> The new upstream image uses `${PWD}/data → /var/www/FreshRSS/data` —
> different host path AND different internal layout. The per-user SQLite
> files are portable between images though, so for each user you can copy
> `./fresh-rss/www/freshrss/data/users/<username>/*` into
> `./data/users/<username>/` after first boot (which creates the parent
> dirs). Verify FreshRSS sees feed history before deleting the old volume.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` + 4 minimum caps (`NET_BIND_SERVICE`, `SETUID`, `SETGID`, `CHOWN`) | Verified minimum by test — no NET_*/SYS_* beyond what Apache strictly needs |
| Privileges | `security_opt: no-new-privileges` | Setuid binaries cannot gain caps |
| IPC | `ipc: private` | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` | Caps fork sprawl |
| Memory / CPU | 512 MiB / 1 CPU limit | Won't starve other stacks |
| Port exposure | `127.0.0.1:88:80` | Only the reverse proxy can reach FreshRSS |
| Single-process | Apache as PID 1, no s6-overlay | Smaller attack surface than wrapped images |
| Healthcheck | `wget /i/` (unauthenticated endpoint) | No credentials on the command line |
| Ephemeral writes | `tmpfs` for `/tmp` (128 MiB) | PHP session files never hit disk |

## Why the upstream-official image (and not LSIO)?

This template uses `freshrss/freshrss:1.29.0-alpine` rather than
`lscr.io/linuxserver/freshrss`. The trade-offs:

| Dimension | `freshrss/freshrss` (upstream) | `lscr.io/linuxserver/freshrss` |
|---|---|---|
| Maintainer | FreshRSS project itself | LinuxServer.io community |
| Patch latency for 1.29.0 | Same day as upstream release | ~7 days later |
| Init | Apache as PID 1 (single process) | s6-overlay tree |
| Caps needed with `cap_drop: ALL` | 4 | 6 (s6 needs DAC_OVERRIDE + FOWNER) |
| Image size (compressed) | 25 MiB (Alpine variant) | 35 MiB |
| PUID/PGID | Not natively (use `user:`) | Native env vars |

For "secure by default" — same-day patches + smaller surface + fewer
caps — the upstream image wins on every security axis. The one operational
trade-off is no PUID/PGID convenience; the data dir ends up owned by the
container's apache user (UID 82) on the host.

## When to switch off SQLite

FreshRSS officially endorses the default SQLite install "for most cases."
Move to an external database only when:

- You have hundreds of users hammering the UI concurrently
- You're tracking thousands of feeds and want Postgres trigram full-text
  search indexes for faster article search
- You're already centralizing other apps onto a shared Postgres/MariaDB
  and would rather consolidate

FreshRSS supports **MariaDB/MySQL** and **PostgreSQL** as alternatives
to SQLite. See the [official database docs](https://freshrss.github.io/FreshRSS/en/admins/DatabaseConfig.html)
and pick the engine during the install wizard (you'll need to spin up
the DB container yourself — that's beyond this template).

## Mobile Apps

FreshRSS supports these mobile apps via API:

- **Android**: FeedMe, EasyRSS, Readrops
- **iOS**: Reeder, Unread, lire
- **Cross-platform**: NetNewsWire

Enable the API in FreshRSS settings under "Authentication".

## Support the Project

- ⭐ [Star on GitHub](https://github.com/FreshRSS/FreshRSS)
- 🐛 [Report Issues](https://github.com/FreshRSS/FreshRSS/issues)
- 💻 [Contribute Code](https://github.com/FreshRSS/FreshRSS/pulls)

## Docker Image

This template uses [`freshrss/freshrss:1.29.0-alpine`](https://hub.docker.com/r/freshrss/freshrss),
the upstream-official image maintained directly by the FreshRSS project.
See the "Why the upstream-official image" section above for the comparison
against the LSIO build.

## License

FreshRSS is released under the [AGPL-3.0 License](https://github.com/FreshRSS/FreshRSS/blob/edge/LICENSE.txt).