# Authentik

<p align="center">
  <img src="https://goauthentik.io/img/icon_left_brand.svg" alt="Authentik Logo" width="400">
</p>

<p align="center">
  <a href="https://goauthentik.io/">Website</a> •
  <a href="https://docs.goauthentik.io/">Documentation</a> •
  <a href="https://github.com/goauthentik/authentik">GitHub</a> •
  <a href="https://goauthentik.io/discord/">Discord</a>
</p>

---

[Authentik](https://goauthentik.io/) is an open-source identity provider offering modern, flexible, and secure authentication and authorization. Perfect for self-hosted deployments or integrating with existing infrastructure.

## Features

- **Single Sign-On (SSO)** — Centralized authentication for all your applications
- **Multiple Protocols** — OAuth2, OIDC, SAML, LDAP, and SCIM support
- **Multi-Factor Authentication** — TOTP, WebAuthn, and more
- **User Management** — Intuitive interface for users, groups, and permissions
- **Customizable Flows** — Build custom authentication workflows
- **Self-Hosted** — Full control over your identity infrastructure

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)

## Quick Start

### 1. Generate Required Secrets

```bash
echo "PG_PASS=$(openssl rand -base64 36 | tr -d '\n')" >> .env
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .env
```

### 2. Configure Environment

Edit `.env` and update:
- `PG_USER` — PostgreSQL username
- `AUTHENTIK_EMAIL__*` — SMTP settings for email notifications
- `COMPOSE_PORT_HTTP` / `COMPOSE_PORT_HTTPS` — Port mappings

### 3. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name

### 4. Deploy

```bash
docker compose up -d
```

### 5. Initial Setup

1. Access Authentik at `https://your-domain/if/flow/initial-setup/`
2. Create your admin account
3. Configure applications and providers

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PG_USER` | PostgreSQL username | `authentik` |
| `PG_PASS` | PostgreSQL password | (required) |
| `AUTHENTIK_SECRET_KEY` | Secret key for encryption | (required) |
| `AUTHENTIK_EMAIL__HOST` | SMTP server | - |
| `AUTHENTIK_EMAIL__PORT` | SMTP port | `587` |
| `AUTHENTIK_EMAIL__FROM` | Sender email address | - |

### Reverse Proxy (Caddy)

```
auth.example.com {
    reverse_proxy http://localhost:9000
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 9000 | HTTP | Web interface |
| 9443 | HTTPS | Web interface (TLS) |

## Support the Project

- ⭐ [Star on GitHub](https://github.com/goauthentik/authentik)
- 💬 [Join Discord](https://goauthentik.io/discord/)
- 💵 [Sponsor Development](https://github.com/sponsors/goauthentik)
- 🎟️ [Enterprise License](https://goauthentik.io/pricing/)

## License

Authentik is released under the [MIT License](https://github.com/goauthentik/authentik/blob/main/LICENSE).