# Watchtower

<p align="center">
  <img src="https://containrrr.dev/watchtower/images/logo-450px.png" alt="Watchtower Logo" width="200">
</p>

<p align="center">
  <a href="https://containrrr.dev/watchtower/">Website</a> •
  <a href="https://containrrr.dev/watchtower/">Documentation</a> •
  <a href="https://github.com/containrrr/watchtower">GitHub</a>
</p>

---

[Watchtower](https://github.com/containrrr/watchtower) automatically updates your running Docker containers when new images are available. Set it and forget it — your containers stay up to date.

## Features

- **Automatic Updates** — Pulls new images and restarts containers
- **Label-Based Control** — Choose which containers to update
- **Notifications** — Email, Slack, Teams, and more
- **Cleanup** — Removes old images after updates
- **Scheduling** — Update on your preferred schedule
- **Private Registries** — Support for authenticated registries

## Prerequisites

- Docker and Docker Compose

## Quick Start

### 1. Configure Notifications (Optional)

Edit `docker-compose.yml` to enable email notifications:

```yaml
environment:
  - WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@example.com
  - WATCHTOWER_NOTIFICATION_EMAIL_TO=admin@example.com
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER=smtp.example.com
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER=your-user
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD=your-password
```

### 2. Deploy

```bash
docker compose up -d
```

Watchtower will now check for updates every 24 hours (default).

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WATCHTOWER_CLEANUP` | Remove old images | `true` |
| `WATCHTOWER_INCLUDE_RESTARTING` | Update restarting containers | `true` |
| `WATCHTOWER_INCLUDE_STOPPED` | Update stopped containers | `true` |
| `WATCHTOWER_REVIVE_STOPPED` | Start stopped containers after update | `true` |
| `WATCHTOWER_LABEL_ENABLE` | Only update labeled containers | `true` |
| `WATCHTOWER_NOTIFICATIONS` | Notification type | `email` |

### Update Interval

The `--interval` flag sets how often Watchtower checks for updates (in seconds):

```yaml
command: --interval 86400  # 24 hours
```

Common intervals:
- `3600` — 1 hour
- `21600` — 6 hours
- `86400` — 24 hours (recommended)
- `604800` — 1 week

## Label-Based Updates

This template uses `WATCHTOWER_LABEL_ENABLE=true`, meaning only containers with the label will be updated.

Add this label to containers you want Watchtower to update:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

All templates in this repository include this label by default.

## Notification Options

### Email

```yaml
- WATCHTOWER_NOTIFICATIONS=email
- WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@example.com
- WATCHTOWER_NOTIFICATION_EMAIL_TO=admin@example.com
- WATCHTOWER_NOTIFICATION_EMAIL_SERVER=smtp.example.com
- WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587
- WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER=user
- WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD=password
```

### Slack

```yaml
- WATCHTOWER_NOTIFICATIONS=slack
- WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://hooks.slack.com/services/xxx
```

### Discord

```yaml
- WATCHTOWER_NOTIFICATIONS=shoutrrr
- WATCHTOWER_NOTIFICATION_URL=discord://token@webhookid
```

## Data Persistence

| Path | Description |
|------|-------------|
| `/var/run/docker.sock` | Docker socket (required) |
| `/etc/timezone` | Host timezone (read-only) |

## Manual Update Trigger

To manually trigger an update check:

```bash
docker exec watchtower /watchtower --run-once
```

## Excluding Containers

To prevent a container from being updated, either:

1. Don't add the Watchtower label, or
2. Add the disable label:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

## Monitoring Watchtower

Check Watchtower's logs:

```bash
docker logs watchtower
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/containrrr/watchtower)
- 📖 [Documentation](https://containrrr.dev/watchtower/)
- 🐛 [Report Issues](https://github.com/containrrr/watchtower/issues)

## License

Watchtower is released under the [Apache-2.0 License](https://github.com/containrrr/watchtower/blob/main/LICENSE.md).