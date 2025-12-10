# Open WebUI

<p align="center">
  <img src="https://docs.openwebui.com/img/logo-dark.png" alt="Open WebUI Logo" width="200">
</p>

<p align="center">
  <a href="https://openwebui.com/">Website</a> •
  <a href="https://docs.openwebui.com/">Documentation</a> •
  <a href="https://github.com/open-webui/open-webui">GitHub</a> •
  <a href="https://discord.gg/open-webui">Discord</a>
</p>

---

[Open WebUI](https://github.com/open-webui/open-webui) is a free and open-source web interface for interacting with Large Language Models. A privacy-friendly, self-hosted alternative to ChatGPT.

## Features

- **Multi-Model Support** — Connect to Ollama, OpenAI, and other providers
- **Conversation History** — All chats stored locally
- **Multi-User Ready** — Role-based access control
- **RAG Support** — Upload documents for context
- **Model Management** — Download and manage Ollama models
- **Customizable** — Themes, personas, and custom prompts
- **API Compatible** — Works with OpenAI-compatible APIs

## Prerequisites

- Docker and Docker Compose
- External Docker network
- Reverse proxy (Caddy, Nginx, Traefik)
- Ollama or OpenAI API access

## Quick Start

### 1. Update Docker Compose

Edit `docker-compose.yml`:
- Replace `your-network` with your Docker network name

### 2. Deploy

```bash
docker compose up -d
```

### 3. Initial Setup

1. Access Open WebUI at `http://your-server:8071`
2. Create an admin account (first user becomes admin)
3. Configure your LLM backend in Settings → Connections

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `OLLAMA_BASE_URL` | Ollama API URL | - |
| `OPENAI_API_KEY` | OpenAI API key | - |
| `WEBUI_AUTH` | Enable authentication | `true` |

### Reverse Proxy (Caddy)

```
chat.example.com {
    reverse_proxy http://localhost:8071
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8071 | HTTP | Web interface |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | Database, uploads, and settings |

## Connecting to Ollama

If Ollama runs on the same host:

```yaml
environment:
  - OLLAMA_BASE_URL=http://host.docker.internal:11434
```

If Ollama runs in Docker on the same network:

```yaml
environment:
  - OLLAMA_BASE_URL=http://ollama:11434
```

## SSO with Authentik

Uncomment and configure OAuth settings in `docker-compose.yml`:

```yaml
- ENABLE_OAUTH_SIGNUP=true
- OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true
- OAUTH_PROVIDER_NAME=authentik
- OPENID_PROVIDER_URL=https://auth.example.com/application/o/openwebui/
- OAUTH_CLIENT_ID=your-client-id
- OAUTH_CLIENT_SECRET=your-client-secret
- OAUTH_SCOPES=openid email profile
- OPENID_REDIRECT_URI=https://chat.example.com/oauth/oidc/callback
```

## Support the Project

- ⭐ [Star on GitHub](https://github.com/open-webui/open-webui)
- 💵 [Sponsor on GitHub](https://github.com/sponsors/open-webui)
- 💬 [Join Discord](https://discord.gg/open-webui)
- 🐛 [Report Issues](https://github.com/open-webui/open-webui/issues)

## License

Open WebUI is released under the [MIT License](https://github.com/open-webui/open-webui/blob/main/LICENSE).