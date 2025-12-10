# Nextcloud AIO

<p align="center">
  <img src="https://nextcloud.com/media/nextcloud-logo.svg" alt="Nextcloud Logo" width="300">
</p>

<p align="center">
  <a href="https://nextcloud.com/">Website</a> •
  <a href="https://github.com/nextcloud/all-in-one">GitHub</a> •
  <a href="https://help.nextcloud.com/">Community</a>
</p>

---

[Nextcloud All-in-One](https://github.com/nextcloud/all-in-one) is the official deployment method for Nextcloud. It provides a single Docker container that manages all Nextcloud components including the database, Redis, collabora, and more.

## Features

- **All-in-One Deployment** — Single container manages everything
- **Auto Updates** — Automatic updates for all components
- **Built-in Backup** — Borg-based backup solution
- **Office Integration** — Collabora Online included
- **Full-Text Search** — Elasticsearch integration
- **Easy Management** — Web-based admin interface

## Prerequisites

- Docker and Docker Compose
- External Docker network (`nextcloud-aio`)
- Reverse proxy (Caddy, Nginx, Traefik)
- Domain name pointing to your server

## Quick Start

### 1. Create Docker Network

```bash
docker network create nextcloud-aio
```

### 2. Create Data Directory

```bash
sudo mkdir -p /mnt/nextcloud-data
sudo chown 33:33 /mnt/nextcloud-data
```

### 3. Update Docker Compose

Edit `docker-compose.yml`:
- Update `NEXTCLOUD_DATADIR` if needed
- Adjust `NEXTCLOUD_UPLOAD_LIMIT` for your needs
- Modify backup settings (`BORG_RETENTION_POLICY`)

### 4. Deploy

```bash
docker compose up -d
```

### 5. Initial Setup

1. Access the AIO interface at `https://your-server:8080`
2. Copy the initial password from the logs:
   ```bash
   docker logs nextcloud-aio-mastercontainer
   ```
3. Follow the setup wizard
4. Configure your domain and start the containers

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APACHE_PORT` | Internal Apache port | `11000` |
| `APACHE_IP_BINDING` | IP to bind Apache | `127.0.0.1` |
| `NEXTCLOUD_DATADIR` | Data directory path | `/mnt/nextcloud-data` |
| `NEXTCLOUD_UPLOAD_LIMIT` | Max upload size | `40G` |
| `NEXTCLOUD_MAX_TIME` | Max execution time | `7600` |
| `NEXTCLOUD_MEMORY_LIMIT` | PHP memory limit | `2048M` |
| `BORG_RETENTION_POLICY` | Backup retention | `--keep-within=7d...` |

### Reverse Proxy (Caddy)

```
nextcloud.example.com {
    reverse_proxy http://localhost:11000
}
```

**Important:** Your reverse proxy must pass the correct headers. See the [official documentation](https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md).

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8080 | HTTPS | AIO management interface |
| 11000 | HTTP | Nextcloud (after setup) |

## Data Persistence

| Path | Description |
|------|-------------|
| `nextcloud_aio_mastercontainer` | AIO configuration volume |
| `/mnt/nextcloud-data` | User files and data |

## Backup & Restore

Nextcloud AIO includes built-in Borg backup. Configure in the AIO interface:

1. Set backup location
2. Configure schedule
3. Set retention policy

To restore, use the AIO interface's restore function.

## GPU Transcoding

To enable hardware transcoding for Memories/Preview generation, uncomment:

```yaml
NEXTCLOUD_ENABLE_DRI_DEVICE: true
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/nextcloud/all-in-one)
- 💵 [Enterprise Support](https://nextcloud.com/enterprise/)
- 💬 [Community Forum](https://help.nextcloud.com/)
- 🐛 [Report Issues](https://github.com/nextcloud/all-in-one/issues)

## License

Nextcloud is released under the [AGPL-3.0 License](https://github.com/nextcloud/server/blob/master/COPYING).