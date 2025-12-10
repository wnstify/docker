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

### 1. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name
- Update `TZ` to your timezone

### 2. Deploy

```bash
docker compose up -d
```

### 3. Initial Setup

1. Access FreshRSS at your configured domain
2. Follow the installation wizard
3. Create your admin account
4. Start adding RSS feeds

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `TZ` | Timezone | `Etc/UTC` |

### Reverse Proxy (Caddy)

```
rss.example.com {
    reverse_proxy http://localhost:88
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 88 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./fresh-rss` | Configuration and data |

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

This template uses the [LinuxServer.io](https://docs.linuxserver.io/images/docker-freshrss/) image, which provides regular updates and consistent configuration.

## License

FreshRSS is released under the [AGPL-3.0 License](https://github.com/FreshRSS/FreshRSS/blob/edge/LICENSE.txt).