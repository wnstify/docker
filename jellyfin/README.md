# Jellyfin

<p align="center">
  <img src="https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/banner-logo-solid.svg" alt="Jellyfin Logo" width="400">
</p>

<p align="center">
  <a href="https://jellyfin.org/">Website</a> •
  <a href="https://jellyfin.org/docs/">Documentation</a> •
  <a href="https://github.com/jellyfin/jellyfin">GitHub</a> •
  <a href="https://discord.com/invite/jellyfin-772232779534172171">Discord</a>
</p>

---

[Jellyfin](https://jellyfin.org/) is a free and open-source media server. Manage and stream your movies, TV shows, music, and photos with no tracking, no central servers, and complete privacy.

## Features

- **Completely Free** — No subscriptions, no paywalls
- **Multi-Platform** — Clients for web, mobile, TV, and desktop
- **Live TV & DVR** — Watch and record live television
- **Rich Metadata** — Automatic media information and artwork
- **User Profiles** — Multiple users with parental controls
- **Hardware Acceleration** — GPU transcoding support
- **Plugins** — Extend functionality with community plugins

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)
- Media files accessible to the container

## Quick Start

### 1. Prepare Media Directories

Ensure your media directories exist and are accessible:

```bash
# Example structure
/media-data/
├── media/
├── movies/
└── shows/
```

### 2. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name
- Update `TZ` to your timezone
- Modify volume paths to match your media locations

### 3. Deploy

```bash
docker compose up -d
```

### 4. Initial Setup

1. Access Jellyfin at `http://your-server:8096`
2. Follow the setup wizard
3. Add your media libraries
4. Create user accounts

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `TZ` | Timezone | `Europe/Bratislava` |

### Reverse Proxy (Caddy)

```
jellyfin.example.com {
    reverse_proxy http://localhost:8096
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8096 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./config` | Jellyfin configuration |
| `/data/media` | Media files (read-only) |
| `/data/movies` | Movies (read-only) |
| `/data/shows` | TV Shows (read-only) |

## Hardware Acceleration

To enable GPU transcoding, uncomment the `devices` section in `docker-compose.yml`:

```yaml
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128
  - /dev/dri/card0:/dev/dri/card0
```

Then enable hardware acceleration in Jellyfin's Dashboard → Playback settings.

## Client Apps

Jellyfin has official and third-party apps for:

- **Web** — Built-in web interface
- **Android** — Jellyfin for Android
- **iOS** — Jellyfin Mobile, Swiftfin
- **TV** — Android TV, Fire TV, Roku, webOS, Tizen
- **Desktop** — Jellyfin Media Player

## Support the Project

- ⭐ [Star on GitHub](https://github.com/jellyfin/jellyfin)
- 💵 [Donate via OpenCollective](https://opencollective.com/jellyfin)
- 💬 [Join Discord](https://discord.com/invite/jellyfin-772232779534172171)
- 🐛 [Report Issues](https://github.com/jellyfin/jellyfin/issues)

## Docker Image

This template uses the [LinuxServer.io](https://docs.linuxserver.io/images/docker-jellyfin/) image for reliable updates and consistent configuration.

## License

Jellyfin is released under the [GPL-2.0 License](https://github.com/jellyfin/jellyfin/blob/master/LICENSE).