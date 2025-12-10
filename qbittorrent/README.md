# qBittorrent

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/6/66/New_qBittorrent_Logo.svg" alt="qBittorrent Logo" width="150">
</p>

<p align="center">
  <a href="https://www.qbittorrent.org/">Website</a> •
  <a href="https://github.com/qbittorrent/qBittorrent/wiki">Wiki</a> •
  <a href="https://github.com/qbittorrent/qBittorrent">GitHub</a> •
  <a href="https://www.reddit.com/r/qBittorrent/">Reddit</a>
</p>

---

[qBittorrent](https://www.qbittorrent.org/) is a free, open-source BitTorrent client with a feature-rich web interface. No ads, no bloat — just a powerful torrent client.

## Features

- **Web UI** — Full-featured web interface for remote access
- **No Ads** — Completely advertisement-free
- **RSS Support** — Subscribe to feeds with download filters
- **Search Engine** — Built-in torrent search
- **IP Filtering** — Block peers with IP filter lists
- **Bandwidth Scheduling** — Limit speeds by time of day
- **Sequential Download** — Download files in order for streaming

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)

## Quick Start

### 1. Prepare Download Directories

Create directories for your downloads:

```bash
mkdir -p /media-data/movies /media-data/shows
```

### 2. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name
- Update `TZ` to your timezone
- Modify volume paths to your download locations

### 3. Deploy

```bash
docker compose up -d
```

### 4. Get Initial Password

```bash
docker logs qbittorrent 2>&1 | grep "temporary password"
```

### 5. Initial Setup

1. Access qBittorrent at `http://your-server:9160`
2. Login with username `admin` and the temporary password
3. Go to **Tools** → **Options** → **Web UI**
4. Change the default password immediately

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `TZ` | Timezone | `Europe/Bratislava` |
| `WEBUI_PORT` | Web interface port | `9160` |

### Reverse Proxy (Caddy)

```
torrent.example.com {
    reverse_proxy http://localhost:9160
}
```

**Note:** Enable "Bypass authentication for clients on localhost" or configure the reverse proxy headers.

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 9160 | HTTP | Web interface |
| 6881 | TCP/UDP | BitTorrent traffic |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | qBittorrent configuration |
| `/movies` | Movie downloads |
| `/shows` | TV show downloads |

## Integration with Media Servers

Use the same download paths in Jellyfin/Plex for automatic library updates:

```yaml
# qBittorrent
- /media-data/movies:/movies
- /media-data/shows:/shows

# Jellyfin (same paths)
- /media-data/movies:/data/movies
- /media-data/shows:/data/shows
```

## Recommended Settings

### Downloads

- **Default Save Path**: `/movies` or `/shows`
- **Keep incomplete torrents in**: Enabled, separate folder

### Connection

- **Global maximum connections**: 500
- **Maximum connections per torrent**: 100

### Speed

- **Alternative Rate Limits**: Enable for scheduled bandwidth limits

### Web UI

- **Enable HTTPS**: If not using reverse proxy
- **Bypass authentication for localhost**: Enable if using reverse proxy

## Support the Project

- ⭐ [Star on GitHub](https://github.com/qbittorrent/qBittorrent)
- 💵 [Donate](https://www.qbittorrent.org/donate)
- 🐛 [Report Issues](https://github.com/qbittorrent/qBittorrent/issues)
- 💬 [Reddit Community](https://www.reddit.com/r/qBittorrent/)

## Docker Image

This template uses the [LinuxServer.io](https://docs.linuxserver.io/images/docker-qbittorrent/) image for reliable updates and consistent configuration.

## License

qBittorrent is released under the [GPL-2.0 License](https://github.com/qbittorrent/qBittorrent/blob/master/COPYING).