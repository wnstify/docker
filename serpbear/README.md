# SerpBear

<p align="center">
  <img src="https://i.imgur.com/0S2zIH3.png" alt="SerpBear Logo" width="400">
</p>

<p align="center">
  <a href="https://serpbear.com/">Website</a> •
  <a href="https://docs.serpbear.com/">Documentation</a> •
  <a href="https://github.com/towfiqi/serpbear">GitHub</a> •
  <a href="https://hub.docker.com/r/towfiqi/serpbear">Docker Hub</a>
</p>

---

[SerpBear](https://serpbear.com/) is an open-source search engine position tracker and keyword research app. It checks Google rankings for the keywords you care about, stores the history, and notifies you when positions move.

## Features

- **Unlimited Keywords** — Track as many domains and keywords as you want
- **SERP History** — Daily rank checks with historical charts
- **Email Notifications** — Daily, weekly, or monthly digests of position changes
- **REST API** — Bearer-token API for dashboards and reporting tools
- **Google Search Console** — Pull real impressions, clicks, and CTR for tracked keywords
- **Keyword Research** — Generate keyword ideas via Google Ads test-account integration
- **Pluggable Scrapers** — serper.dev, serpapi, SearchApi, valueserp, hasdata, crazyserp, or your own proxy IPs
- **Mobile PWA** — Installable web app for phones

## Prerequisites

- Docker and Docker Compose
- One external Docker network (`serpbear-front`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS
- A scraping provider API key OR proxy IPs (set in-app after first login)

## Quick Start

### 1. Create Docker Network

```bash
docker network create serpbear-front
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Three values are **required** and must be set before first boot:

```bash
# Strong login password
openssl rand -base64 24

# Session JWT secret + REST API bearer token (two separate values)
openssl rand -hex 32
openssl rand -hex 32
```

Paste them into `SERPBEAR_PASSWORD`, `SERPBEAR_SECRET`, and `SERPBEAR_APIKEY`. Also set `SERPBEAR_URL` to the public hostname your reverse proxy will serve.

### 3. Deploy

```bash
mkdir -p data
sudo chown -R 1001:1001 data   # image's bundled non-root user
docker compose up -d
```

The first boot runs Sequelize migrations on a fresh SQLite database; once you see `Listening on port 3000` the `/` endpoint reports healthy.

### 4. Initial Setup

Visit `https://seo.example.com` (or `http://localhost:3000` for local testing) and log in with `SERPBEAR_USER` / `SERPBEAR_PASSWORD`. Then:

1. **Settings → Scraper** — pick a provider and paste its API key (or configure proxy IPs)
2. **Domains → Add Domain** — enter your site
3. **Add Keywords** — paste keywords with country/device targeting
4. (Optional) **Settings → Notifications** — configure SMTP and digest frequency
5. (Optional) **Settings → Integrations** — connect Google Search Console / Ads

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `SERPBEAR_PASSWORD` | Login password for the single admin account | Yes |
| `SERPBEAR_SECRET` | Signs session JWTs (64 hex chars) | Yes |
| `SERPBEAR_APIKEY` | REST API bearer token (64 hex chars) | Yes |
| `SERPBEAR_URL` | Public URL with scheme (used for emails, OAuth callbacks, CSRF) | Yes |
| `SERPBEAR_USER` | Login username | No (default `admin`) |
| `SERPBEAR_SESSION_DURATION` | Session lifetime in hours | No (default `24`) |
| `SERPBEAR_PORT` | Host port (127.0.0.1 only) | No (default `3000`) |
| `SEARCH_CONSOLE_CLIENT_EMAIL` | Google service-account email for GSC integration | No |
| `SEARCH_CONSOLE_PRIVATE_KEY` | Google service-account private key | No |
| `PUID` / `PGID` | Host UID/GID owning `./data` | No (default `1001`) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

Note: SerpBear's upstream image maps the env var to `USER_NAME` internally because `USER` is a reserved shell variable — this compose handles the rename for you.

### Reverse Proxy (Caddy)

```caddyfile
seo.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:3000
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 3000 | HTTP | Next.js web UI + REST API (reverse-proxy target) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | SQLite database, `settings.json`, failed-scrape queue, cron state |

## API Usage

The REST API uses a bearer token equal to `SERPBEAR_APIKEY`:

```bash
curl -H "Authorization: Bearer ${SERPBEAR_APIKEY}" \
  https://seo.example.com/api/domains
```

See the [SerpBear API docs](https://docs.serpbear.com/api) for the full route list.

## Scraping Providers

SerpBear ships with multiple scraper integrations — pick one based on your volume and budget:

| Provider | Cost | Typical use case |
|---|---|---|
| serper.dev | $1/1000 req (pay as you go) | Low volume, simple |
| serpapi.com | From $50/mo | Mid volume |
| SearchApi.io | From $40/mo | Mid volume |
| crazyserp.com | From $47/mo (100k req) | High volume |
| Own proxies | Your infra | Full control, no third party |

Set the chosen provider's API key in **Settings → Scraper** after first login.

## Google Search Console Integration

1. Create a Google Cloud project + service account
2. Share the property in Search Console with the service-account email (read-only)
3. Paste `SEARCH_CONSOLE_CLIENT_EMAIL` and `SEARCH_CONSOLE_PRIVATE_KEY` into `.env`
4. `docker compose up -d` to apply

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL`, **zero `cap_add`** (verified by test, May 2026) | No Linux capabilities granted |
| Non-root | Runs as `${PUID}:${PGID}` (default `1001:1001`, image's bundled `nextjs` user) | No root in the container |
| Privileges | `security_opt: no-new-privileges` | Setuid binaries cannot gain caps |
| IPC | `ipc: private` | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` | Caps fork sprawl |
| Port exposure | `127.0.0.1` only on 3000 | Only the reverse proxy can reach SerpBear |
| Secrets pinned | `SECRET` + `APIKEY` set via `.env` | Sessions and API tokens survive restarts |
| Healthcheck | wget against the Next.js root | Boot gated by simple HTTP check |
| No DB tier | Embedded SQLite in `./data` | One container, one network, no extra secrets |

## Support the Project

- [Star on GitHub](https://github.com/towfiqi/serpbear)
- [Sponsor on GitHub](https://github.com/sponsors/towfiqi)
- [Report Issues](https://github.com/towfiqi/serpbear/issues)

## License

SerpBear is released under the [MIT License](https://github.com/towfiqi/serpbear/blob/main/LICENSE).
