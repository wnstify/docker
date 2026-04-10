# Usage Guide

## Deployment

### 1. Generate Configuration

```bash
./generate-config.sh <domain>
```

The script auto-detects your UID/GID and generates all config files and secrets. The detected values are stored as `PUID`/`PGID` in `.env`.

If you need a different user:
```bash
sed -i 's/^PUID=.*/PUID=1001/' .env
sed -i 's/^PGID=.*/PGID=1001/' .env
chown -R 1001:1001 data/meshcentral-data data/meshcentral-files data/meshcentral-backups
```

### 2. Deploy

```bash
docker compose up -d
```

First startup generates TLS certificates and initializes the database.

### 3. Reverse Proxy

Point your reverse proxy to `https://127.0.0.1:4430`. MeshCentral uses self-signed certs internally — your proxy must skip TLS verification to the backend.

**Pangolin**: Target `https://127.0.0.1:4430`, enable TLS skip verify.

**Caddy example**:
```caddyfile
rmm.yourdomain.com {
    reverse_proxy https://127.0.0.1:4430 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

**Nginx example**:
```nginx
location / {
    proxy_pass https://127.0.0.1:4430;
    proxy_ssl_verify off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
}
```

WebSocket headers (`Upgrade`, `Connection`) are required for remote desktop/terminal sessions.

### 4. First Login

1. Visit `https://rmm.yourdomain.com`
2. Create your admin account
3. Edit `data/meshcentral-data/config.json` — set `"newAccounts": false`
4. Restart: `docker compose restart meshcentral`

---

## Configuration

MeshCentral configuration lives in `data/meshcentral-data/config.json`. Edit it directly — the container reads it on startup (`DYNAMIC_CONFIG=false`).

### Common Settings

```json
{
  "settings": {
    "agentPort": 8800,
    "allowHighQualityDesktop": true,
    "compression": true,
    "autoBackup": {
      "backupIntervalHours": 24,
      "keepLastDaysBackup": 7
    }
  },
  "domains": {
    "": {
      "newAccounts": false,
      "title": "My RMM",
      "certUrl": "https://rmm.yourdomain.com/"
    }
  }
}
```

After editing, restart: `docker compose restart meshcentral`

### Email / SMTP

Add to `config.json` under `"domains" > ""`:
```json
{
  "domains": {
    "": {
      "mailServer": {
        "host": "smtp.example.com",
        "port": 587,
        "tls": true,
        "auth": {
          "user": "noreply@example.com",
          "pass": "smtp-password"
        },
        "from": "noreply@example.com"
      }
    }
  }
}
```

### Intel AMT (optional)

Add to `config.json` under `"settings"`:
```json
{
  "settings": {
    "mpsPort": 4433,
    "mpsAliasPort": 4433
  }
}
```

Then add to `docker-compose.yml` ports:
```yaml
ports:
  - "4433:4433"
```

---

## Operations

### Updating

```bash
docker compose pull
docker compose up -d
```

### Logs

```bash
docker compose logs -f meshcentral
docker compose logs -f mongodb
```

### Backup

Automated backups are enabled by default (daily, keep 7 days) in `data/meshcentral-backups/`.

Manual backup:
```bash
docker compose stop
tar -czf meshcentral-backup-$(date +%Y%m%d).tar.gz data/ .env
docker compose up -d
```

### Restore

```bash
docker compose down
tar -xzf meshcentral-backup-YYYYMMDD.tar.gz
docker compose up -d
```

### Full Reset

```bash
docker compose down
docker run --rm -v $(pwd)/data:/data alpine:3 sh -c "rm -rf /data/*"
rm -f .env
rm -rf data/
./generate-config.sh rmm.yourdomain.com
docker compose up -d
```

### Agent Deployment

1. Log into MeshCentral web UI
2. Create a device group
3. Click "Add Agent" — download the agent installer for your OS
4. Deploy to target machines

Agents connect back to your server on port 443 through the reverse proxy (same as web UI).
