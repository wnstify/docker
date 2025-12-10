# SerpBear

<p align="center">
  <img src="https://raw.githubusercontent.com/towfiqi/serpbear/main/public/logo.svg" alt="SerpBear Logo" width="200">
</p>

<p align="center">
  <a href="https://serpbear.com/">Website</a> •
  <a href="https://docs.serpbear.com/">Documentation</a> •
  <a href="https://github.com/towfiqi/serpbear">GitHub</a>
</p>

---

[SerpBear](https://serpbear.com/) is an open-source SEO rank tracking application. Monitor your website's keyword rankings on Google and track your SEO progress over time.

## Features

- **Keyword Tracking** — Monitor rankings for unlimited keywords
- **Multiple Domains** — Track multiple websites
- **SERP History** — Historical ranking data and charts
- **Email Notifications** — Alerts for ranking changes
- **Google Search Console** — Integration for additional data
- **Mobile & Desktop** — Track rankings for both device types
- **API Access** — RESTful API for integrations
- **Self-Hosted** — Full control over your SEO data

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

Generate secure keys:

```bash
# Generate SECRET and APIKEY
openssl rand -hex 32
```

Update these values in `.env`:
- `SERPBEAR_USER` — Login username
- `SERPBEAR_PASSWORD` — Login password (use a strong password)
- `SERPBEAR_SECRET` — Session secret key
- `SERPBEAR_APIKEY` — API access key
- `SERPBEAR_URL` — Your public URL

### 2. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name

### 3. Deploy

```bash
docker compose up -d
```

### 4. Access SerpBear

Navigate to your configured URL and login with your credentials.

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SERPBEAR_USER` | Login username | Yes |
| `SERPBEAR_PASSWORD` | Login password | Yes |
| `SERPBEAR_SECRET` | Session secret key (hex string) | Yes |
| `SERPBEAR_APIKEY` | API access key | Yes |
| `SERPBEAR_URL` | Public URL with https:// | Yes |

### Reverse Proxy (Caddy)

```
seo.example.com {
    reverse_proxy http://localhost:3000
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 3000 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./serpbear_appdata` | Database and application data |

## Adding Keywords

1. Go to **Domains** → **Add Domain**
2. Enter your website URL
3. Add keywords to track
4. Set tracking frequency (daily recommended)

## Google Search Console Integration

1. Create a Google Cloud project
2. Enable Search Console API
3. Create OAuth credentials
4. Add credentials in SerpBear settings

## Avoiding Rate Limits

SerpBear uses scraping to check rankings. To avoid issues:

- Use proxies for high-volume tracking
- Set reasonable check intervals
- Consider using ScrapingBee or similar services

### Proxy Configuration

Configure proxies in the settings:
- HTTP proxies
- SOCKS5 proxies
- Rotating proxy services

## API Usage

Use the API key to access SerpBear's REST API:

```bash
curl -H "Authorization: Bearer YOUR_APIKEY" \
  https://seo.example.com/api/domains
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/towfiqi/serpbear)
- 🐛 [Report Issues](https://github.com/towfiqi/serpbear/issues)
- 💵 [Sponsor Development](https://github.com/sponsors/towfiqi)

## License

SerpBear is released under the [MIT License](https://github.com/towfiqi/serpbear/blob/main/LICENSE).