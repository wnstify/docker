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

| Template | Description | Documentation |
|----------|-------------|---------------|
| **[n8n](./n8n)** | Workflow automation platform (Zapier alternative) with PostgreSQL backend | [README](./n8n/README.md) |
| **[Navidrome](./navidrome)** | Self-hosted music server and streamer compatible with Subsonic/Airsonic | - |
| **[Watchtower](./watchtower)** | Automatic Docker container updates with email notifications | [README](./watchtower/README.md) |

---

## Prerequisites

- **Docker** v20.10 or higher
- **Docker Compose** v2.0 or higher
- A **reverse proxy** (Caddy, Nginx, or Traefik) for HTTPS termination
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

6. **Set up your reverse proxy** (see Caddyfile examples in each template directory)

---

## Directory Structure

```
docker/
├── README.md
├── SECURITY.md
├── n8n/
│   ├── docker-compose.yml    # Main compose file
│   ├── .env                  # Environment variables (gitignored)
│   ├── init-data.sh          # PostgreSQL initialization script
│   ├── Caddyfile             # Reverse proxy example
│   └── README.md             # n8n-specific documentation
├── navidrome/
│   └── docker-compose.yml
└── watchtower/
    ├── docker-compose.yml
    └── README.md
```

---

## Common Configuration

### Environment Variables

Each template uses `.env` files for sensitive configuration. **Never commit credentials to version control.**

### Reverse Proxy

All templates bind to `127.0.0.1` (localhost only) and require a reverse proxy for external access. Example Caddy configuration:

```
your-domain.com {
    reverse_proxy http://localhost:5678
}
```

### Automatic Updates

Templates include Watchtower labels for automatic updates:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

Deploy the [Watchtower template](./watchtower) to enable automatic container updates.

---

## Security Features

All templates are configured with security best practices:

- **`no-new-privileges:true`** — Prevents privilege escalation inside containers
- **Localhost binding** — Services only accessible via reverse proxy
- **Non-root database users** — Principle of least privilege for database access
- **Health checks** — Ensures dependencies are ready before starting dependent services
- **External networks** — Isolated networking between container stacks

For security concerns or vulnerability reports, please see our [Security Policy](SECURITY.md).

---

## About Webnestify

**Webnestify** empowers businesses and developers with tools for managing web infrastructure. We believe in enabling users to:

- **Save Money** — Reduce reliance on costly SaaS tools
- **Own Their Data** — Privacy-focused, self-hosted solutions
- **Simplify Management** — Intuitive tools and educational resources

### What We Offer

- **Managed Services** — Email servers, Cloudflare configuration, dedicated hosting
- **Educational Content** — Tutorials, livestreams, and courses
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
- `README.md` with setup instructions
- `Caddyfile` example for reverse proxy configuration

---

## Support

- **Documentation**: [docs.webnestify.com](https://docs.webnestify.com/)
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