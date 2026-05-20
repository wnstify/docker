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

[Open WebUI](https://github.com/open-webui/open-webui) is a free, open-source web interface for chatting with LLMs. A privacy-friendly self-hosted ChatGPT alternative — point it at Ollama, OpenAI, Anthropic, or any OpenAI-compatible API.

## Features

- **Multi-Model Support** — Ollama, OpenAI, Anthropic, and OpenAI-compatible providers
- **Conversation History** — Chats stored locally in SQLite
- **Multi-User Ready** — Role-based access control, OIDC/SSO via Authentik
- **RAG Support** — Upload documents, embedded ChromaDB vector store
- **Tools & Functions** — Extend with custom Python tools
- **Image Generation** — Optional Stable Diffusion / AUTOMATIC1111 / ComfyUI integration

## Prerequisites

- Docker and Docker Compose
- One external Docker network (`openwebui-front`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS
- A model provider (see [Connecting to a Model Provider](#connecting-to-a-model-provider))

## Quick Start

### 1. Create Docker Network

```bash
docker network create openwebui-front
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

The only **required** value is `WEBUI_SECRET_KEY` — Open WebUI signs session cookies with it. Without it the secret is regenerated on every restart and every user gets logged out.

```bash
openssl rand -hex 32
```

### 3. Deploy

```bash
mkdir -p data
docker compose up -d
```

First boot downloads the sentence-transformers embedding model (~100 MB, used for RAG). The `/health` endpoint reports healthy once startup completes.

### 4. Initial Setup

Visit `https://chat.example.com` (or `http://localhost:8071` for local testing). The first account you create becomes the admin. Configure your model provider in **Settings → Connections**.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `WEBUI_SECRET_KEY` | Signs session cookies (64 hex chars) | Yes |
| `WEBUI_AUTH` | `true` for built-in login, `false` if you front it with Authentik in proxy mode | No (default `true`) |
| `OWUI_PORT` | Host port (127.0.0.1 only) | No (default 8071) |
| `OLLAMA_BASE_URL` | URL of your Ollama instance | No |
| `OPENAI_API_KEY` | OpenAI API key | No |
| `ANTHROPIC_API_KEY` | Anthropic API key | No |
| `OAUTH_*` | Authentik OIDC SSO settings | No |
| `PUID` / `PGID` | Host UID/GID for the container | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

Full [Open WebUI environment reference](https://docs.openwebui.com/getting-started/env-configuration).

### Reverse Proxy (Caddy)

WebSocket support is required for streaming responses:

```caddyfile
chat.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:8071
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8071 | HTTP | Web interface (reverse-proxy target) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | SQLite database, uploads, ChromaDB vector store, downloaded embedding models |

## Connecting to a Model Provider

Open WebUI needs at least one provider to actually chat. Pick whichever fits:

### Ollama on the same Docker host

```bash
# in .env
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

You may need to add `extra_hosts: ["host.docker.internal:host-gateway"]` to the compose service if `host.docker.internal` doesn't resolve.

### Ollama in another compose stack

Create a shared network, join both containers to it:

```bash
docker network create ollama-net
# add `ollama-net` to openwebui-front's networks: list in this compose
# add `ollama-net` to the ollama service's networks: list
```

Then:

```bash
# in .env
OLLAMA_BASE_URL=http://ollama:11434
```

### External API (OpenAI, Anthropic, etc.)

```bash
# in .env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

You can mix providers — the UI lets users pick which model per chat.

## SSO with Authentik

1. In Authentik, create an OAuth2/OpenID provider with redirect URI `https://chat.example.com/oauth/oidc/callback` and scopes `openid email profile`.
2. Create an Authentik application linked to that provider.
3. Set the `OAUTH_*` block in `.env` (see `.env.example`) and restart:

```bash
docker compose up -d
```

If you want to fully delegate auth to Authentik (proxy mode), set `WEBUI_AUTH=false` and front Open WebUI with Authentik's proxy outpost.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL`, **zero `cap_add`** (verified by test, May 2026) | No Linux capabilities granted |
| Non-root | Runs as `${PUID}:${PGID}` (default 1000) | No root in the container |
| Privileges | `security_opt: no-new-privileges` | Setuid binaries cannot gain caps |
| IPC | `ipc: private` | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 300` | Caps fork sprawl |
| Port exposure | `127.0.0.1` only on 8071 | Only the reverse proxy can reach Open WebUI |
| Secret pinned | `WEBUI_SECRET_KEY` set via `.env` | Sessions survive restarts; not regenerated on every boot |
| Healthcheck | Built-in `/health` endpoint | Boot gated by simple HTTP check |

## Support the Project

- ⭐ [Star on GitHub](https://github.com/open-webui/open-webui)
- 💵 [Sponsor on GitHub](https://github.com/sponsors/open-webui)
- 💬 [Join Discord](https://discord.gg/open-webui)
- 🐛 [Report Issues](https://github.com/open-webui/open-webui/issues)

## License

Open WebUI is released under the [MIT License](https://github.com/open-webui/open-webui/blob/main/LICENSE).
