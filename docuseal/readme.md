# DocuSeal

<p align="center">
  <img src="https://www.docuseal.co/logo.svg" alt="DocuSeal Logo" width="300">
</p>

<p align="center">
  <a href="https://www.docuseal.co/">Website</a> •
  <a href="https://www.docuseal.co/docs">Documentation</a> •
  <a href="https://github.com/docusealco/docuseal">GitHub</a>
</p>

---

[DocuSeal](https://www.docuseal.co/) is an open-source document signing platform that allows you to create, fill, and sign digital documents. A self-hosted alternative to DocuSign and HelloSign.

## Features

- **Document Templates** — Create reusable document templates
- **Digital Signatures** — Legally binding electronic signatures
- **Form Fields** — Text, signature, date, checkbox, and more
- **PDF Support** — Upload and process PDF documents
- **API Access** — Integrate with your applications
- **Self-Hosted** — Full control over sensitive documents

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)
- DocuSeal license (get from [DocuSeal Dashboard](https://console.docuseal.co/))

## Quick Start

### 1. Get Your Docker Image

1. Sign up at [DocuSeal Console](https://console.docuseal.co/)
2. Get your personalized Docker image URL
3. Update `docker-compose.yml` with your image URL

### 2. Configure Environment

Copy and edit the environment file:

```bash
cp .env.example .env
nano .env
```

Update these values:
- `POSTGRES_USER` / `POSTGRES_PASSWORD` — Database root credentials
- `POSTGRES_NON_ROOT_USER` / `POSTGRES_NON_ROOT_PASSWORD` — Application user

### 3. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `GET-FROM-DOCUSEAL-DASHBOARD` with your image URL
- Update `FORCE_SSL` to your domain
- Configure SMTP settings for email notifications
- Replace network names as needed

### 4. Create Docker Networks

```bash
docker network create docuseal
docker network create docuseal-db
```

### 5. Deploy

```bash
docker compose up -d
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | PostgreSQL root username | `replace` |
| `POSTGRES_PASSWORD` | PostgreSQL root password | `replace` |
| `POSTGRES_DB` | Database name | `replace` |
| `POSTGRES_NON_ROOT_USER` | Application DB username | `replace` |
| `POSTGRES_NON_ROOT_PASSWORD` | Application DB password | `replace` |
| `FORCE_SSL` | Public URL with HTTPS | (required) |
| `SECRET_KEY_BASE` | Rails secret key | (required) |
| `SMTP_*` | Email configuration | - |

### Reverse Proxy (Caddy)

```
docuseal.example.com {
    reverse_proxy http://localhost:3000
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 3000 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./db_storage` | PostgreSQL data |
| `./data` | DocuSeal documents and data |

## Architecture

This deployment includes:
- **docuseal-app** — Main application
- **docuseal-postgres** — PostgreSQL database
- **docuseal-gotenberg** — PDF processing service

## Support the Project

- ☁️ [DocuSeal Cloud](https://www.docuseal.co/pricing) — Managed hosting
- ⭐ [Star on GitHub](https://github.com/docusealco/docuseal)
- 📖 [Documentation](https://www.docuseal.co/docs)

## License

DocuSeal is released under the [AGPL-3.0 License](https://github.com/docusealco/docuseal/blob/master/LICENSE).