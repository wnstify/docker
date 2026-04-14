# Stoat — Self-Hosted Discord Alternative

Hardened Docker Compose deployment of [Stoat](https://stoat.chat) (formerly Revolt), a self-hosted, open-source chat platform with text channels, voice/video calls, file sharing, bots, and a polished web UI.

This setup follows strict container hardening standards: `cap_drop: ALL`, `no-new-privileges`, `ipc: private`, `read_only` where possible, resource limits, internal network segmentation, and healthchecks.

## Architecture

15 containers across 5 isolated Docker networks:

```
Internet
  |
Pangolin (TLS termination + SSO)
  |
127.0.0.1:8880
  |
[stoat-frontend] ── Caddy (path router)
  |
[stoat-app] ── web, api, events, autumn, january, gifbox, livekit, voice-ingress
  |
[stoat-data] ── MongoDB, Redis, Garage S3
[stoat-rabbit] ── RabbitMQ
[stoat-voice] ── LiveKit, Redis
```

### Services

| Service | Image | Purpose |
|---------|-------|---------|
| **api** | `ghcr.io/stoatchat/api:v0.12.1` | REST API (Rust) |
| **events** | `ghcr.io/stoatchat/events:v0.12.1` | WebSocket real-time messaging |
| **autumn** | `ghcr.io/stoatchat/file-server:v0.12.1` | File upload/download |
| **january** | `ghcr.io/stoatchat/proxy:v0.12.1` | Link preview & image proxy |
| **gifbox** | `ghcr.io/stoatchat/gifbox:v0.12.1` | Tenor GIF proxy |
| **crond** | `ghcr.io/stoatchat/crond:v0.12.1` | Scheduled cleanup tasks |
| **pushd** | `ghcr.io/stoatchat/pushd:v0.12.1` | Web push notifications |
| **voice-ingress** | `ghcr.io/stoatchat/voice-ingress:v0.12.1` | Voice channel routing |
| **livekit** | `ghcr.io/stoatchat/livekit-server:v1.9.13` | Voice/video WebRTC server |
| **web** | `ghcr.io/stoatchat/for-web:0b94704` | Solid.js web frontend |
| **caddy** | `caddy:2.11.2` | Internal path-based reverse proxy |
| **database** | `mongo:8` | Primary database |
| **redis** | `redis:8-alpine` | Cache & pub/sub |
| **rabbit** | `rabbitmq:4.2.5-alpine` | Internal message broker |
| **garage** | `dxflrs/garage:v2.2.0` | S3-compatible object storage |

### Infrastructure Requirements

- 2 vCPU / 4 GB RAM minimum
- Docker + Docker Compose
- Reverse proxy with TLS (Pangolin, Caddy, nginx, etc.)
- `openssl` for secret generation
- A domain name

## Quick Start

```bash
# 1. Generate configuration
./generate-config.sh chat.yourdomain.com --enable-video

# 2. Review config
nano Revolt.toml   # set invite_only = true if needed

# 3. Deploy
docker compose up -d
```

Then point your reverse proxy to `127.0.0.1:8880` and open firewall ports `7881/tcp` + `50000-50100/udp` for voice/video.

The first account created becomes the instance owner.

See [USAGE.md](USAGE.md) for detailed deployment and operations guide.
See [SECURITY.md](SECURITY.md) for the full security model.

## Files

```
stoat/
  docker-compose.yml      # Hardened Docker Compose (15 services)
  Caddyfile               # Internal path router
  generate-config.sh      # One-command config + secret generator
  init-scripts/
    init-garage.sh        # Garage S3 bootstrap (runs once)
  README.md               # This file
  USAGE.md                # Deployment & operations guide
  SECURITY.md             # Security model documentation
```

Generated at deploy time (not committed):
```
  .env                    # Infrastructure credentials (chmod 600)
  secrets.env             # Application secrets (chmod 600)
  .env.web                # Frontend environment variables
  Revolt.toml             # Stoat configuration
  garage.toml             # Garage S3 config
  livekit.yml             # LiveKit voice server config
  data/                   # Persistent data directories
```

## License

Stoat is licensed under [AGPL-3.0](https://github.com/stoatchat/stoatchat/blob/main/LICENSE).

## Acknowledgements

❤️ Huge thanks to the [Stoat](https://stoat.chat) (formerly Revolt) developers, [Garage](https://garagehq.deuxfleurs.fr/) by Deuxfleurs, [LiveKit](https://livekit.io/), [MongoDB](https://www.mongodb.com/), [Redis](https://redis.io/), [RabbitMQ](https://www.rabbitmq.com/), [Caddy](https://caddyserver.com/), and the entire open-source community that makes self-hosted, privacy-respecting infrastructure possible. Your work gives people a real choice. We appreciate every contributor, tester, and community member who keeps these projects alive.

## Managed Hosting

Don't want to manage this yourself? [Webnestify](https://webnestify.cloud) offers fully managed, hardened self-hosted deployments — Stoat, AI tools, and more — on dedicated infrastructure with monitoring, backups, and ongoing maintenance included.
