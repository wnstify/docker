# Portainer CE

<p align="center">
  <img src="https://www.portainer.io/hubfs/portainer-logo-black.svg" alt="Portainer Logo" width="300">
</p>

<p align="center">
  <a href="https://www.portainer.io/">Website</a> •
  <a href="https://docs.portainer.io/">Documentation</a> •
  <a href="https://github.com/portainer/portainer">GitHub</a> •
  <a href="https://forums.portainer.io/">Community</a>
</p>

---

[Portainer Community Edition](https://www.portainer.io/) is a lightweight container management UI for Docker, Docker Swarm, and Kubernetes. Simplify container operations with a beautiful web interface.

## Features

- **Intuitive Web UI** — Manage containers, images, volumes, and networks
- **Multi-Environment** — Docker, Swarm, and Kubernetes support
- **Stack Deployment** — Deploy Docker Compose stacks from the UI
- **Container Management** — Start, stop, logs, console access
- **Image Registry** — Connect to Docker Hub and private registries
- **Role-Based Access** — User management with fine-grained permissions
- **Templates** — Quick deployment from app templates

## Prerequisites

- Docker and Docker Compose
- External Docker network

## Quick Start

### 1. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name

### 2. Deploy

```bash
docker compose up -d
```

### 3. Initial Setup

1. Access Portainer at `https://your-server:9443`
2. Create an admin account (within 5 minutes of deployment)
3. Select "Get Started" to manage the local Docker environment

## Configuration

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 9443 | HTTPS | Web interface (recommended) |
| 9000 | HTTP | Web interface (insecure) |
| 8000 | TCP | Edge agent communication |

### Reverse Proxy (Caddy)

```
portainer.example.com {
    reverse_proxy https://localhost:9443 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

## Data Persistence

| Path | Description |
|------|-------------|
| `./portainer/portainer_data` | Portainer configuration and data |
| `/var/run/docker.sock` | Docker socket (required) |

## Managing Remote Hosts

To manage remote Docker hosts:

1. Deploy [Portainer Agent](../portainer-agent) on remote hosts
2. In Portainer, go to **Environments** → **Add environment**
3. Select **Agent** and enter the remote agent URL

## Common Tasks

### Deploy a Stack

1. Go to **Stacks** → **Add stack**
2. Paste your Docker Compose YAML
3. Click **Deploy the stack**

### View Container Logs

1. Go to **Containers**
2. Click on a container name
3. Select **Logs** from the menu

### Access Container Console

1. Go to **Containers**
2. Click on a container name
3. Select **Console** and choose your shell

## Backup

Backup the data directory regularly:

```bash
tar -czvf portainer-backup.tar.gz ./portainer/portainer_data
```

## Upgrading to Business Edition

Portainer BE offers additional features:
- RBAC with more granular controls
- OAuth/LDAP authentication
- Registry management
- Activity logging

Learn more at [portainer.io/business](https://www.portainer.io/business)

## Support the Project

- ⭐ [Star on GitHub](https://github.com/portainer/portainer)
- 📖 [Documentation](https://docs.portainer.io/)
- 💬 [Community Forums](https://forums.portainer.io/)
- 🎟️ [Business Edition](https://www.portainer.io/business)

## License

Portainer CE is released under the [zlib License](https://opensource.org/licenses/Zlib).