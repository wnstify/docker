# NGINX Proxy Manager

<p align="center">
  <img src="https://nginxproxymanager.com/logo.svg" alt="NGINX Proxy Manager Logo" width="300">
</p>

<p align="center">
  <a href="https://nginxproxymanager.com/">Website</a> •
  <a href="https://nginxproxymanager.com/guide/">Documentation</a> •
  <a href="https://github.com/NginxProxyManager/nginx-proxy-manager">GitHub</a>
</p>

---

[NGINX Proxy Manager](https://nginxproxymanager.com/) provides a beautiful web interface for managing reverse proxies with automatic SSL certificates. Perfect for exposing your Docker services securely.

## Features

- **Web Interface** — Easy-to-use GUI for proxy management
- **Free SSL** — Automatic Let's Encrypt certificates
- **Access Lists** — IP-based access control
- **Custom SSL** — Upload your own certificates
- **Redirections** — HTTP to HTTPS and custom redirects
- **Streams** — TCP/UDP proxy support
- **404 Hosts** — Custom 404 pages

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Ports 80 and 443 available on your server

## Quick Start

### 1. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name

### 2. Deploy

```bash
docker compose up -d
```

### 3. Initial Setup

1. Access the admin panel at `http://your-server:81`
2. Login with default credentials:
   - **Email**: `admin@example.com`
   - **Password**: `changeme`
3. **Immediately** change the default email and password

### 4. Add Proxy Hosts

1. Go to "Proxy Hosts" → "Add Proxy Host"
2. Enter your domain name
3. Set the forward hostname/IP and port
4. Enable SSL and select "Force SSL"

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DISABLE_IPV6` | Disable IPv6 support | `true` |
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 80 | HTTP | Web traffic (redirects to HTTPS) |
| 443 | HTTPS | Secure web traffic |
| 81 | HTTP | Admin panel |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | NPM configuration and database |
| `./ssl` | SSL certificates |

## Common Tasks

### Adding a New Service

1. Deploy your service bound to localhost (e.g., `127.0.0.1:8080`)
2. In NPM, add a new Proxy Host:
   - Domain: `service.yourdomain.com`
   - Forward Hostname: `your-service-container` or `host.docker.internal`
   - Forward Port: `8080`
3. Enable SSL with Let's Encrypt

### Protecting Services with Authentication

1. Go to "Access Lists" → "Add Access List"
2. Add users with passwords
3. Apply the access list to your proxy host

### Wildcard SSL Certificates

1. Add a new SSL certificate
2. Choose "Let's Encrypt" with DNS Challenge
3. Enter `*.yourdomain.com` as the domain
4. Configure your DNS provider credentials

## Networking

For NPM to reach other containers, they must share a Docker network:

```yaml
# In your service's docker-compose.yml
networks:
  - your-network

networks:
  your-network:
    external: true
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/NginxProxyManager/nginx-proxy-manager)
- 💵 [Donate](https://www.buymeacoffee.com/jc21)
- 🐛 [Report Issues](https://github.com/NginxProxyManager/nginx-proxy-manager/issues)

## License

NGINX Proxy Manager is released under the [MIT License](https://github.com/NginxProxyManager/nginx-proxy-manager/blob/develop/LICENSE).