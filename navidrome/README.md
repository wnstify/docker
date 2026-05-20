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

[Navidrome](https://www.navidrome.org/) is a modern, open-source music server and streamer. Subsonic/Airsonic-compatible, so it works with dozens of mobile apps.

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
- One external Docker network (`navidrome-front`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS
- A music library on the host, readable by your UID

## Quick Start

### 1. Prepare Your Music Library

Make sure your music folder is organized and readable by `${PUID}:${PGID}`:

```
/path/to/your/music/
├── Artist 1/
│   ├── Album 1/
│   └── Album 2/
└── Artist 2/
    └── Album 1/
```

### 2. Create Docker Network

```bash
docker network create navidrome-front
```

### 3. Configure Environment

```bash
cp .env.example .env
nano .env
```

The only **required** value is `MUSIC_DIR` — the absolute path to your music library on the host. Everything else has sensible defaults.

Optional: fill in `ND_LASTFM_*` or `ND_SPOTIFY_*` for richer artist/album metadata.

### 4. Deploy

```bash
mkdir -p data
docker compose up -d
```

First boot scans the music library and reports healthy via `/ping`.

### 5. Initial Setup

Visit `https://music.example.com` (or `http://localhost:4533` for local testing) and create the admin account on first login.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `MUSIC_DIR` | Absolute path to your music library on the host | Yes |
| `NAVIDROME_PORT` | Host port (127.0.0.1 only) | No (default 4533) |
| `ND_LOGLEVEL` | Log verbosity (`debug`, `info`, `warn`, `error`) | No (default `info`) |
| `ND_SCANSCHEDULE` | Music scan schedule (cron-ish: `1h`, `@every 1h`, `30m`) | No (default `1h`) |
| `ND_SESSIONTIMEOUT` | Session expiration | No (default `24h`) |
| `ND_BASEURL` | Reverse-proxy subpath (e.g. `/music`) | No |
| `ND_LASTFM_APIKEY` / `ND_LASTFM_SECRET` | Last.fm metadata enrichment | No |
| `ND_SPOTIFY_ID` / `ND_SPOTIFY_SECRET` | Spotify metadata enrichment | No |
| `PUID` / `PGID` | Host UID/GID for the container | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

Full [Navidrome configuration reference](https://www.navidrome.org/docs/usage/configuration-options/) lists every `ND_*` env var you can override.

### Reverse Proxy (Caddy)

```caddyfile
music.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:4533
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 4533 | HTTP | Web interface + Subsonic API (reverse-proxy target) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | Navidrome SQLite database, cache, and transcoding cache |
| `${MUSIC_DIR}` | Music library — **mounted read-only**, container cannot modify your files |

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL`, **zero `cap_add`** (verified by test, May 2026) | No Linux capabilities granted |
| Non-root | Runs as `${PUID}:${PGID}` (default 1000) | No root in the container |
| Privileges | `security_opt: no-new-privileges` | Setuid binaries cannot gain caps |
| IPC | `ipc: private` | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` | Caps fork sprawl |
| Music library | Mounted `:ro` | Container can scan/stream but cannot rename/move/delete files |
| Port exposure | `127.0.0.1` only on 4533 | Only the reverse proxy can reach Navidrome |
| Healthcheck | Built-in `/ping` endpoint | Boot gated by simple HTTP check |
| No DB tier | Embedded SQLite in `./data` | One container, one network, no extra secrets |

## Compatible Apps

Navidrome works with Subsonic-compatible apps:

- **Android**: DSub, Ultrasonic, Symfonium, Tempo
- **iOS**: play:Sub, Amperfy, SubStreamer, Substreamer
- **Desktop**: Sublime Music, Sonixd, Feishin
- **Web**: Built-in web player

## Support the Project

- ⭐ [Star on GitHub](https://github.com/navidrome/navidrome)
- 💵 [Sponsor on GitHub](https://github.com/sponsors/deluan)
- 💬 [Join Discord](https://discord.gg/xh7j7yF)
- 🐛 [Report Issues](https://github.com/navidrome/navidrome/issues)

## License

Navidrome is released under the [GPL-3.0 License](https://github.com/navidrome/navidrome/blob/master/LICENSE).
