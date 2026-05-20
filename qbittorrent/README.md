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
- One external Docker network (`qbittorrent-front`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS on the WebUI
- A downloads directory on the host, writable by your `${PUID}:${PGID}`
- A port on your router/firewall forwarded to the BitTorrent listen port

## Quick Start

### 1. Create Docker Network

```bash
docker network create qbittorrent-front
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Required values:

- `DOWNLOADS_DIR` — absolute host path to your downloads directory (mounted as `/downloads` inside the container)
- `QBT_LEGAL_NOTICE=confirm` — the upstream image refuses to start without this; setting it affirms you have read qBittorrent's [legal notice](https://github.com/qbittorrent/qBittorrent/blob/master/src/app/main.cpp)

### 3. Deploy

```bash
mkdir -p data
docker compose up -d
```

### 4. Get the Initial Admin Password

qBittorrent (>= 4.6.1) generates a temporary admin password on first boot and prints it to stdout:

```bash
docker logs qbittorrent 2>&1 | grep -i "temporary password"
```

### 5. Initial Setup

1. Visit `https://torrent.example.com` (or `http://localhost:9160` for local testing).
2. Log in as `admin` with the temporary password from step 4.
3. **Immediately** change the password in **Tools -> Options -> Web UI -> Authentication**.
4. Set the default save path under **Tools -> Options -> Downloads -> Default Save Path** to `/downloads` (or a subdir like `/downloads/movies`).

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `DOWNLOADS_DIR` | Absolute host path mounted as `/downloads` | Yes |
| `QBT_LEGAL_NOTICE` | Must be `confirm` (image refuses to start otherwise) | Yes |
| `QBT_WEBUI_HOST_PORT` | WebUI host port (127.0.0.1 only) | No (default 9160) |
| `QBT_TORRENT_PORT` | BitTorrent listen port (TCP + UDP, all interfaces) | No (default 6881) |
| `PUID` / `PGID` | Host UID/GID the container runs as | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

The image's own envs (`QBT_VERSION`, `UMASK`, `PAGID`) are not exposed in this template because the image tag is pinned here and the others are rarely needed. Add them under `environment:` if you need them — see the [upstream image README](https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox).

### Reverse Proxy (Caddy)

```caddyfile
torrent.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:9160
}
```

In qBittorrent's WebUI, enable **Bypass authentication for clients on localhost** (under **Web UI -> Authentication**) so your reverse proxy doesn't hit the login form on every request. If you front it with Authentik or similar SSO instead, keep auth enabled and pass the proxy headers through.

## Ports

| Port | Protocol | Binding | Description |
|------|---------|---------|-------------|
| 9160 | TCP | 127.0.0.1 only | WebUI (reverse-proxy target) |
| 6881 | TCP + UDP | All interfaces | BitTorrent listen port (peers connect inbound) |

The BitTorrent listen port has to be reachable from the public internet for inbound peer connections — that is why it is published on all interfaces, not just localhost. Forward it in your router and (if applicable) open it in your host firewall.

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | qBittorrent config (`qBittorrent.conf`, session state, `.fastresume` cache) |
| `${DOWNLOADS_DIR}` | Downloaded files — written through to the host |

## Integration with Media Servers

Use the same host path in qBittorrent and Jellyfin/Plex so finished downloads appear in your library without a copy step. For example:

```yaml
# qbittorrent/.env
DOWNLOADS_DIR=/media-data/downloads

# jellyfin docker-compose.yml volumes:
- /media-data/downloads:/media/downloads
```

Then point your *arr stack (Sonarr, Radarr) at qBittorrent's WebUI and have them move completed files into your media library subdirectories.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL`, **zero `cap_add`** (verified by test, May 2026) | No Linux capabilities granted |
| Non-root | Compose `user: ${PUID}:${PGID}` (default 1000) | Image's entrypoint skips its root-only chown/doas branch entirely |
| Privileges | `security_opt: no-new-privileges` | Setuid binaries cannot gain caps |
| IPC | `ipc: private` | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 300` | Caps fork sprawl |
| WebUI exposure | `127.0.0.1` only on the WebUI host port | Only the reverse proxy can reach the WebUI |
| Graceful shutdown | `stop_grace_period: 30m` | Lets qBittorrent flush DHT + checkpoint torrents (default 10 s corrupts in-progress downloads) |
| Healthcheck | busybox `wget --spider /` | Boot gated by HTTP listener check |
| Image | Upstream-official `qbittorrentofficial/qbittorrent-nox`, not LSIO | Patched same day as qBittorrent releases; no s6-overlay wrapper |

### Why the upstream-official image, not LinuxServer.io?

- **Maintained by the qBittorrent project directly** (publisher: `sledgehammer999`)
- **Single-process container** — qbittorrent-nox is PID 1, no s6-overlay init layer
- **Patched same-day** as upstream releases (LSIO typically trails)
- **~190 MB compressed**, multi-arch (`amd64`, `arm64`, `armv7`, `armv6`, `riscv64`, `386`)
- **Read-only filesystem capable** out of the box (we don't use it here because `user:` + read-only is incompatible per upstream README)

## Recommended In-App Settings

After login, under **Tools -> Options**:

- **Downloads -> Default Save Path**: `/downloads` (or a subdirectory)
- **Downloads -> Keep incomplete torrents in**: enable, e.g. `/downloads/incomplete`
- **Connection -> Port used for incoming connections**: matches `QBT_TORRENT_PORT` from `.env`
- **Connection -> Global maximum connections**: 500 (default is sensible)
- **Web UI -> Bypass authentication for clients on localhost**: enable if behind a trusted reverse proxy
- **Speed -> Alternative Rate Limits**: enable + schedule for off-peak unmetered bandwidth

## Support the Project

- [Star on GitHub](https://github.com/qbittorrent/qBittorrent)
- [Donate](https://www.qbittorrent.org/donate)
- [Report Issues](https://github.com/qbittorrent/qBittorrent/issues)
- [Reddit Community](https://www.reddit.com/r/qBittorrent/)

## License

qBittorrent is released under the [GPL-2.0 License](https://github.com/qbittorrent/qBittorrent/blob/master/COPYING).
