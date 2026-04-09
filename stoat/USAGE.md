# Usage Guide

## Deployment

### 1. Generate Configuration

```bash
./generate-config.sh <domain> [--enable-video]
```

This creates all config files and data directories:

| File | Purpose |
|------|---------|
| `.env` | Infrastructure credentials (MongoDB, Redis, RabbitMQ, Garage) |
| `secrets.env` | Stoat application secrets (VAPID keys, encryption keys, LiveKit) |
| `.env.web` | Frontend environment variables (API URLs, WebSocket URLs) |
| `Revolt.toml` | Stoat configuration (hosts, features, limits) |
| `garage.toml` | Garage S3 storage configuration |
| `livekit.yml` | LiveKit voice/video server configuration |
| `data/` | Persistent data directories |

Both `.env` and `secrets.env` are created with `chmod 600`.

### 2. Configure Stoat

Edit `Revolt.toml` before starting:

```toml
# Make instance invite-only
[api.registration]
invite_only = true

# Add Tenor API key for GIF support (free from Google Cloud Console)
[api.security]
tenor_key = "your-tenor-api-key"

# Add SMTP for email verification
[api.smtp]
host = "smtp.example.com"
username = "noreply@example.com"
password = "smtp-password"
from_address = "noreply@example.com"
```

### 3. Start the Stack

```bash
docker compose up -d
```

First startup pulls ~3 GB of images. The `garage-init` container automatically configures S3 storage (layout, bucket, API keys) and exits.

### 4. Reverse Proxy

Point your reverse proxy to `127.0.0.1:8880`. Caddy handles internal path-based routing:

| Path | Backend Service |
|------|----------------|
| `/` | web (frontend) |
| `/api/*` | api (REST API) |
| `/ws` | events (WebSocket) |
| `/autumn/*` | autumn (file server) |
| `/january/*` | january (link proxy) |
| `/gifbox/*` | gifbox (GIF proxy) |
| `/livekit/*` | livekit (voice signaling) |
| `/ingress/*` | voice-ingress |

### 5. Firewall

Open these ports for voice/video:

| Port | Protocol | Purpose |
|------|----------|---------|
| 7881 | TCP | LiveKit TCP signaling fallback |
| 50000-50100 | UDP | WebRTC media (voice/video) |

### 6. First Login

Visit `https://yourdomain.com` and register. The first account becomes the instance owner.

---

## Operations

### Updating

```bash
docker compose pull
docker compose up -d
```

Check the [Stoat self-hosted repo](https://github.com/stoatchat/self-hosted) for breaking changes before updating.

### Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api

# Last 50 lines
docker compose logs --tail 50 api
```

### Restart a Service

```bash
docker compose restart api
```

### Database Access

```bash
# MongoDB shell
docker compose exec database mongosh -u <user> -p <pass> --authenticationDatabase admin revolt

# Redis CLI
docker compose exec redis redis-cli -a <password>
```

### Invite-Only Mode

Enable in `Revolt.toml`:
```toml
[api.registration]
invite_only = true
```

Create invite codes:
```bash
docker compose exec database mongosh -u <user> -p <pass> --authenticationDatabase admin revolt \
  --eval 'db.invites.insertOne({ _id: "your-invite-code" })'
```

Then restart the API: `docker compose restart api`

### Disable Email Verification

If you don't have SMTP configured:
```toml
[api.registration]
email_verification = false
```

### Backup

All persistent data is under `./data/`:

| Path | Content |
|------|---------|
| `data/db/` | MongoDB (messages, users, servers, channels) |
| `data/garage-meta/` | Garage metadata |
| `data/garage-data/` | Garage object data (uploaded files) |
| `data/redis/` | Redis persistence |
| `data/rabbit/` | RabbitMQ state |

Backup strategy:
```bash
# Stop services for consistent backup
docker compose stop

# Archive
tar -czf stoat-backup-$(date +%Y%m%d).tar.gz data/ .env secrets.env Revolt.toml garage.toml livekit.yml .env.web

# Restart
docker compose up -d
```

For hot backups, use `mongodump` for MongoDB and snapshot Garage via its admin API.

### Restore

```bash
tar -xzf stoat-backup-YYYYMMDD.tar.gz
docker compose up -d
```

### Full Reset

```bash
docker compose down
docker run --rm -v $(pwd)/data:/data alpine:3 sh -c "rm -rf /data/*"
rm -f .env secrets.env .env.web Revolt.toml garage.toml livekit.yml
rm -rf data/
# Regenerate
./generate-config.sh yourdomain.com --enable-video
docker compose up -d
```
