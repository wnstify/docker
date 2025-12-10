# Portainer Agent

<p align="center">
  <img src="https://www.portainer.io/hubfs/portainer-logo-black.svg" alt="Portainer Logo" width="300">
</p>

<p align="center">
  <a href="https://www.portainer.io/">Website</a> •
  <a href="https://docs.portainer.io/">Documentation</a> •
  <a href="https://github.com/portainer/agent">GitHub</a>
</p>

---

The [Portainer Agent](https://github.com/portainer/agent) enables secure communication between a Portainer server and remote Docker environments. Deploy it on remote hosts to manage them from a central Portainer instance.

## Features

- **Remote Management** — Manage Docker hosts from a central location
- **Secure Communication** — Encrypted WebSocket connections
- **Multi-Environment** — Works with Docker standalone, Swarm, and Kubernetes
- **Lightweight** — Minimal resource footprint
- **Auto-Discovery** — Automatically detects containers, networks, and volumes
- **Firewall-Friendly** — Single port communication

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Portainer CE or BE server (see [portainer-ce](../portainer-ce))

## Quick Start

### 1. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name

### 2. Deploy

```bash
docker compose up -d
```

### 3. Connect to Portainer

1. In your Portainer server, go to **Environments** → **Add environment**
2. Select **Agent**
3. Enter the agent URL: `your-remote-host:9001`
4. Give it a name and connect

## Configuration

### Environment Variables

The agent works with default settings, but you can customize:

| Variable | Description | Default |
|----------|-------------|---------|
| `AGENT_CLUSTER_ADDR` | Address for cluster communication | - |
| `AGENT_SECRET` | Shared secret for authentication | - |
| `LOG_LEVEL` | Logging verbosity | `INFO` |

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 9001 | TCP | Agent API |

## Data Persistence

| Path | Description |
|------|-------------|
| `/var/run/docker.sock` | Docker socket (required) |
| `/var/lib/docker/volumes` | Docker volumes (for browsing) |

## Security Considerations

### Firewall Rules

Only allow port 9001 from your Portainer server:

```bash
# UFW example
ufw allow from YOUR_PORTAINER_IP to any port 9001
```

### Agent Secret

For additional security, set a shared secret:

```yaml
environment:
  - AGENT_SECRET=your-secure-secret
```

Then configure the same secret in Portainer when adding the environment.

## Multiple Hosts

Deploy the agent on each remote host you want to manage. Each agent gets its own entry in Portainer.

## Troubleshooting

### Agent Not Connecting

1. Check firewall allows port 9001
2. Verify Docker socket is mounted correctly
3. Check agent logs: `docker logs portainer-agent`

### Permission Issues

Ensure the Docker socket is accessible:

```bash
ls -la /var/run/docker.sock
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/portainer/portainer)
- 📖 [Documentation](https://docs.portainer.io/)
- 💬 [Community Forums](https://forums.portainer.io/)

## License

Portainer Agent is released under the [zlib License](https://opensource.org/licenses/Zlib).