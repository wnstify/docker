![Webnestify Logo](https://webnestify.cloud/wp-content/uploads/2023/11/webnestify-logo-dark-300x109.png)

# Webnestify Docker Project Templates

[![GitHub Stars](https://img.shields.io/github/stars/wnstify/docker?style=flat-square)](https://github.com/wnstify/docker/stargazers)
[![GitHub License](https://img.shields.io/github/license/wnstify/docker?style=flat-square)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/wnstify/docker?style=flat-square)](https://github.com/wnstify/docker/commits/main)

Production-ready Docker Compose templates for self-hosting open-source applications. Each template includes security hardening, health checks, and automatic updates via Watchtower.

---

## Table of Contents

- [Available Templates](#available-templates)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Common Configuration](#common-configuration)
- [Security Features](#security-features)
- [About Webnestify](#about-webnestify)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## Available Templates

### Productivity & Automation

| Template | Description | Docs |
|----------|-------------|------|
| [n8n](./n8n) | Workflow automation platform (Zapier alternative) with PostgreSQL | [README](./n8n/README.md) |
| [Baserow](./baserow) | No-code database platform (Airtable alternative) with PostgreSQL | [README](./baserow/README.md) |
| [DocuSeal](./docuseal) | Document signing and forms platform | - |

### Media & Entertainment

| Template | Description | Docs |
|----------|-------------|------|
| [Jellyfin](./jellyfin) | Free media server for movies, TV, and music | [README](./jellyfin/README.md) |
| [Navidrome](./navidrome) | Self-hosted music server (Subsonic/Airsonic compatible) | - |
| [qBittorrent](./qbittorrent) | Feature-rich BitTorrent client with web UI | [README](./qbittorrent/README.md) |

### Infrastructure & DevOps

| Template | Description | Docs |
|----------|-------------|------|
| [Portainer CE](./portainer-ce) | Docker container management UI | [README](./portainer-ce/README.md) |
| [Portainer Agent](./portainer-agent) | Remote Docker environment management | [README](./portainer-agent/README.md) |
| [NGINX Proxy Manager](./npm) | Reverse proxy with SSL management UI | [README](./npm/README.md) |
| [Watchtower](./watchtower) | Automatic Docker container updates | [README](./watchtower/README.md) |
| [Uptime Kuma](./uptime-kuma) | Self-hosted monitoring and status pages | [README](./uptime-kuma/README.md) |

### Identity & Security

| Template | Description | Docs |
|----------|-------------|------|
| [Authentik](./authentik) | Identity provider with SSO, OAuth2, SAML, LDAP | [README](./authentik/README.md) |

### Communication & Collaboration

| Template | Description | Docs |
|----------|-------------|------|
| [Zulip](./zulip) | Threaded team chat (Slack alternative) | - |
| [Open WebUI](./openwebui) | Web interface for LLMs (ChatGPT alternative) | [README](./openwebui/README.md) |

### Content & Information

| Template | Description | Docs |
|----------|-------------|------|
| [FreshRSS](./freshrss) | Self-hosted RSS feed aggregator | [README](./freshrss/README.md) |
| [SerpBear](./serpbear) | SEO rank tracking tool | - |
| [Nextcloud AIO](./nextcloud-aio) | All-in-one file sync and collaboration platform | [README](./nextcloud-aio/README.md) |

---

## Prerequisites

- **Docker** v20.10 or higher
- **Docker Compose** v2.0 or higher
- A **reverse proxy** (Caddy, Nginx Proxy Manager, or Traefik) for HTTPS termination
- A **Docker network** for inter-container communication

### Create a Docker Network

Before deploying any template, create an external network:

```bash
docker network create your-network
```

Replace `your-network` with your preferred network name and update all `docker-compose.yml` files accordingly.

---

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/wnstify/docker.git
   cd docker
   ```

2. **Choose a template** and navigate to its directory
   ```bash
   cd n8n
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env   # If .env.example exists
   nano .env              # Edit with your values
   ```

4. **Update the docker-compose.yml**
   - Replace `your-network` with your Docker network name
   - Update domain names, paths, and credentials marked with `# Change Value`

5. **Deploy the stack**
   ```bash
   docker compose up -d
   ```

6. **Set up your reverse proxy** (see Caddyfile examples in template directories)

---

## Directory Structure

```
docker/
├── README.md
├── SECURITY.md
├── LICENSE
├── .gitignore
│
├── authentik/
│   ├── docker-compose.yml
│   ├── .env
│   └── README.md
│
├── baserow/
│   ├── docker-compose.yml
│   ├── .env
│   ├── init-data.sh
│   ├── Caddyfile
│   └── README.md
│
├── docuseal/
│   ├── docker-compose.yml
│   ├── .env
│   └── init-data.sh
│
├── freshrss/
│   ├── docker-compose.yml
│   └── README.md
│
├── jellyfin/
│   ├── docker-compose.yml
│   └── README.md
│
├── n8n/
│   ├── docker-compose.yml
│   ├── .env
│   ├── init-data.sh
│   ├── Caddyfile
│   └── README.md
│
├── navidrome/
│   └── docker-compose.yml
│
├── nextcloud-aio/
│   ├── docker-compose.yml
│   └── README.md
│
├── npm/
│   ├── docker-compose.yml
│   └── README.md
│
├── openwebui/
│   ├── docker-compose.yml
│   └── README.md
│
├── portainer-agent/
│   ├── docker-compose.yml
│   └── README.md
│
├── portainer-ce/
│   ├── docker-compose.yml
│   └── README.md
│
├── qbittorrent/
│   ├── docker-compose.yml
│   └── README.md
│
├── serpbear/
│   └── docker-compose.yml
│
├── uptime-kuma/
│   ├── docker-compose.yml
│   ├── .env
│   └── README.md
│
├── watchtower/
│   ├── docker-compose.yml
│   └── README.md
│
└── zulip/
    ├── docker-compose.yml
    └── .env
```

---

## Common Configuration

### Environment Variables

Each template uses `.env` files for sensitive configuration. **Never commit real credentials to version control.**

Example `.env` structure:
```bash
POSTGRES_USER=changeUser
POSTGRES_PASSWORD=changePassword
POSTGRES_DB=appname
```

### Reverse Proxy

All templates bind to `127.0.0.1` (localhost only) and require a reverse proxy for external access.

**Caddy example:**
```
your-domain.com {
    reverse_proxy http://localhost:5678
}
```

**NGINX Proxy Manager:** Use the included [npm template](./npm) for a GUI-based approach.

### Automatic Updates

Templates include Watchtower labels for automatic updates:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

Deploy the [Watchtower template](./watchtower) to enable automatic container updates.

### PostgreSQL Initialization

Several templates (n8n, Baserow, DocuSeal) include an `init-data.sh` script that creates a non-root database user on first run. This follows the principle of least privilege.

---

## Security Features

All templates are configured with security best practices:

| Feature | Description |
|---------|-------------|
| `no-new-privileges:true` | Prevents privilege escalation inside containers |
| Localhost binding | Services only accessible via reverse proxy |
| Non-root database users | Principle of least privilege for database access |
| Health checks | Ensures dependencies are ready before starting services |
| External networks | Isolated networking between container stacks |
| PUID/PGID settings | Consistent file permissions across containers |

For security concerns or vulnerability reports, please see our [Security Policy](SECURITY.md).

---

## About Webnestify

**Webnestify** empowers businesses and developers with tools for managing web infrastructure. We believe in:

- **Saving Money** — Reduce reliance on costly SaaS tools
- **Owning Your Data** — Privacy-focused, self-hosted solutions
- **Simplifying Management** — Intuitive tools and educational resources

### What We Offer

- **Managed Services** — Email servers, Cloudflare configuration, dedicated hosting
- **Educational Content** — Tutorials, livestreams, and courses on [YouTube](https://youtube.com/@webnestify)
- **Open-Source Advocacy** — Tailored solutions that give you full control

Learn more at [webnestify.cloud](https://webnestify.cloud)

---

## Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/new-template`)
3. **Commit** your changes (`git commit -m 'Add new template'`)
4. **Push** to the branch (`git push origin feature/new-template`)
5. **Open** a Pull Request

### Template Guidelines

When adding new templates, please include:

- `docker-compose.yml` with security options and Watchtower labels
- `.env.example` with placeholder values (no real credentials)
- `README.md` with setup instructions and links to official docs
- `Caddyfile` example for reverse proxy configuration (if applicable)
- Bind ports to `127.0.0.1` for reverse proxy setups
- Use `no-new-privileges:true` security option

---

## Support

- **YouTube Tutorials**: [@webnestify](https://youtube.com/@webnestify)
- **Discord Community**: [Join Discord](https://wnstify.cc/discord)
- **Contact**: [webnestify.cloud/contact](https://webnestify.cloud/contact)

### Connect With Us

[![Website](https://img.shields.io/badge/Website-webnestify.cloud-blue?style=flat-square)](https://webnestify.cloud)
[![YouTube](https://img.shields.io/badge/YouTube-@webnestify-red?style=flat-square)](https://youtube.com/@webnestify)
[![Discord](https://img.shields.io/badge/Discord-Join-7289da?style=flat-square)](https://wnstify.cc/discord)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-webnestify-0077b5?style=flat-square)](https://linkedin.com/company/webnestify)
[![Trustpilot](https://img.shields.io/badge/Trustpilot-Reviews-00b67a?style=flat-square)](https://www.trustpilot.com/review/webnestify.cloud)

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

**Webnestify** – Your partner in simplifying web infrastructure.