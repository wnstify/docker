# Navidrome

<p align="center">
  <img src="https://raw.githubusercontent.com/navidrome/navidrome/master/.github/logo.png" alt="Navidrome Logo" width="300">
</p>

<p align="center">
  <a href="https://www.navidrome.org/">Website</a> •
  <a href="https://www.navidrome.org/docs/">Documentation</a> •
  <a href="https://github.com/navidrome/navidrome">GitHub</a> •
  <a href="https://discord.gg/xh7j7yF">Discord</a>
</p>

---

[Navidrome](https://www.navidrome.org/) is a modern, open-source music server and streamer. Compatible with Subsonic/Airsonic clients, it lets you enjoy your music collection from anywhere.

## Features

- **Subsonic API Compatible** — Works with dozens of mobile apps
- **Modern Web UI** — Beautiful, responsive interface
- **Fast & Lightweight** — Handles large collections efficiently
- **Multi-User** — Each user gets their own playlists and favorites
- **On-the-Fly Transcoding** — Stream in any format/bitrate
- **Smart Playlists** — Auto-generated playlists based on criteria
- **Last.fm Scrobbling** — Track your listening history

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)
- Music library accessible to the container

## Quick Start

### 1. Prepare Music Directory

Ensure your music directory exists and is organized:

```bash
/path/to/your/music/
├── Artist 1/
│   ├── Album 1/
│   └── Album 2/
└── Artist 2/
    └── Album 1/
```

### 2. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name
- Update `/path/to/your/music/folder` to your music directory

### 3. Deploy

```bash
docker compose up -d
```

### 4. Initial Setup

1. Access Navidrome at `http://your-server:4533`
2. Create an admin account on first login
3. Wait for the initial music scan to complete

## Configuration

### Environment Variables

Uncomment and configure in `docker-compose.yml`:

| Variable | Description | Default |
|----------|-------------|---------|
| `ND_SCANSCHEDULE` | Music scan schedule | `1h` |
| `ND_LOGLEVEL` | Log verbosity | `info` |
| `ND_SESSIONTIMEOUT` | Session timeout | `24h` |
| `ND_BASEURL` | Base URL if using subpath | `/` |
| `ND_ENABLETRANSCODINGCONFIG` | Allow transcoding config | `true` |

### Reverse Proxy (Caddy)

```
music.example.com {
    reverse_proxy http://localhost:4533
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 4533 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | Navidrome database and cache |
| `/music` | Music library (read-only) |

## Compatible Apps

Navidrome works with Subsonic-compatible apps:

- **Android**: DSub, Ultrasonic, Symfonium
- **iOS**: play:Sub, Amperfy, SubStreamer
- **Desktop**: Sublime Music, Sonixd
- **Web**: Built-in web player

## File Permissions

The container runs as user `1000:1000`. Ensure your music folder is readable:

```bash
# Check current ownership
ls -la /path/to/your/music

# If needed, adjust permissions
chmod -R 755 /path/to/your/music
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/navidrome/navidrome)
- 💵 [Sponsor on GitHub](https://github.com/sponsors/deluan)
- 💬 [Join Discord](https://discord.gg/xh7j7yF)
- 🐛 [Report Issues](https://github.com/navidrome/navidrome/issues)

## License

Navidrome is released under the [GPL-3.0 License](https://github.com/navidrome/navidrome/blob/master/LICENSE).