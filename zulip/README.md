# Zulip

<p align="center">
  <img src="https://zulip.com/static/images/logo/zulip-icon-circle.svg" alt="Zulip Logo" width="150">
</p>

<p align="center">
  <a href="https://zulip.com/">Website</a> •
  <a href="https://zulip.readthedocs.io/">Documentation</a> •
  <a href="https://github.com/zulip/zulip">GitHub</a> •
  <a href="https://chat.zulip.org/">Community</a>
</p>

---

[Zulip](https://zulip.com/) is an open-source team chat application with a unique threading model. Organize conversations by topic for better async communication — a powerful, self-hostable alternative to Slack.

## Features

- **Topic-Based Threading** — Conversations organized by topic within streams
- **Powerful Search** — Find any message instantly, with full-text search (pgroonga)
- **Markdown Support** — Rich formatting, code blocks, LaTeX, syntax highlighting
- **Integrations** — 100+ integrations (GitHub, Jira, GitLab, PagerDuty, etc.)
- **Mobile Apps** — iOS, Android, and desktop applications
- **Guest Access** — Invite external collaborators with restricted permissions
- **Self-Hosted** — Full data ownership, no vendor lock-in

## Prerequisites

- Docker and Docker Compose
- Two external Docker networks (`zulip-front`, `zulip-db`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS
- Domain name with DNS configured
- At least 4 GB RAM available to the stack (Zulip 12 baseline)

## Quick Start

### 1. Create Docker Networks

One of two is `--internal` (no internet egress for the four backing services):

```bash
docker network create zulip-front
docker network create --internal zulip-db
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

The `.env.example` file has `openssl` recipes next to each critical secret. The five that matter most:

- `POSTGRES_PASSWORD`, `MEMCACHED_PASSWORD`, `RABBITMQ_DEFAULT_PASS`, `REDIS_PASSWORD` — one per backing service. Generate each with `openssl rand -base64 36 | tr -d '\n'`.
- `SECRETS_secret_key` — Django's signing key. Used for session cookies, CSRF, password-reset links. **Losing this invalidates all sessions; leaking it lets attackers forge them.** Generate with `openssl rand -base64 60 | tr -d '\n'`.

Also set:

- `SETTING_EXTERNAL_HOST` — public hostname (no scheme, no trailing slash).
- `SETTING_ZULIP_ADMINISTRATOR` — admin email shown on user-facing error pages.
- `LOADBALANCER_IPS` — comma-separated IPs/CIDRs of trusted reverse proxies. **Required when `http_only=True`** so Zulip honors `X-Forwarded-Proto`.

### 3. Create Data Directories with Correct Ownership

All four backing services run non-root with hard-coded UIDs from their respective base images:

```bash
mkdir -p data/{postgres,rabbitmq,redis,zulip}
sudo chown -R 70:70    data/postgres   # postgres user in zulip-postgresql:14
sudo chown -R 999:999  data/rabbitmq   # rabbitmq user in rabbitmq:4.2
sudo chown -R 999:1000 data/redis      # redis user in redis:7.4-alpine
# data/zulip is initialized by the zulip container on first boot.
```

### 4. Deploy

```bash
docker compose up -d
```

First boot takes 4–6 minutes — Zulip applies ~280 Django migrations against a fresh DB and provisions supervisor workers. Watch with `docker compose logs -f zulip`; readiness is reported when the healthcheck flips to `healthy`.

### 5. Create the First Organization

```bash
docker exec -it zulip-server /home/zulip/deployments/current/manage.py generate_realm_creation_link
```

Open the printed URL in your browser to create your organization and its first admin user. The link is single-use.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `POSTGRES_PASSWORD` | PostgreSQL password (backs `zulip` DB user) | Yes |
| `MEMCACHED_PASSWORD` | SASL password for Zulip's memcache user | Yes |
| `RABBITMQ_DEFAULT_PASS` | RabbitMQ password (`zulip` user) | Yes |
| `REDIS_PASSWORD` | Redis `requirepass` | Yes |
| `SECRETS_secret_key` | Django SECRET_KEY (session cookies, CSRF) | Yes |
| `SETTING_EXTERNAL_HOST` | Public hostname (no scheme) | Yes |
| `SETTING_ZULIP_ADMINISTRATOR` | Admin email | Yes |
| `LOADBALANCER_IPS` | Trusted reverse-proxy IPs/CIDRs | Yes (when `http_only=True`) |
| `ZULIP_AUTH_BACKENDS` | Comma-separated backend list | No (default `EmailAuthBackend`) |
| `ZULIP_HTTP_ONLY` | `True` = HTTP to proxy, `False` = self-terminate TLS | No (default `True`) |
| `COMPOSE_PORT_HTTP` | Host port for the 127.0.0.1 binding | No (default `8080`) |
| `SETTING_EMAIL_HOST` / `_HOST_USER` / `_PORT` / `_USE_TLS` | SMTP settings | No |
| `SECRETS_email_password` | SMTP password | No |
| `NOREPLY_EMAIL_ADDRESS` | From: address for system mail | No |

### Reverse Proxy (Caddy)

```caddyfile
chat.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:8080 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

Set `LOADBALANCER_IPS` in `.env` to the bridge-network range Caddy lives on (commonly `127.0.0.1` for a host-local Caddy, or `172.16.0.0/12` if Caddy runs in another Docker network).

### Reverse Proxy (Nginx)

```nginx
server {
    listen 443 ssl http2;
    server_name chat.example.com;
    ssl_certificate     /etc/letsencrypt/live/chat.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/chat.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "upgrade";
        proxy_read_timeout 1200s;  # Tornado long-poll
    }
}
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8080 | HTTP | Web interface (reverse-proxy target, 127.0.0.1-bound) |

Inbound SMTP (port 25) for the Zulip "email-to-Zulip" feature is not exposed by default — wire it manually if you need it.

## Data Persistence

| Path | Owner | Description |
|------|-------|-------------|
| `./data/postgres`  | 70:70    | PostgreSQL 14 datadir (Zulip-specific extensions installed inside the image) |
| `./data/rabbitmq`  | 999:999  | RabbitMQ Mnesia, queues, schema |
| `./data/redis`     | 999:1000 | Redis dump.rdb + appendonly files |
| `./data/zulip`     | (init)   | Uploads, custom emoji, secrets cache, backup spool |

### Backup

```bash
docker compose stop
sudo tar -czvf zulip-backup-$(date +%Y%m%d).tar.gz data/
docker compose start
```

Zulip's `manage.py export_realm` is the upstream-recommended logical backup if you only need org-level data. See [zulip.readthedocs.io/.../export-and-import.html](https://zulip.readthedocs.io/en/latest/production/export-and-import.html).

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` on every service. ZERO `cap_add` on postgres/memcached/rabbitmq/redis (all run non-root); Zulip server adds 6 caps for its supervisor-based init (CHOWN/SETGID/SETUID/DAC_OVERRIDE/FOWNER + NET_BIND_SERVICE for nginx :80) | Verified by test, May 2026 |
| Non-root | postgres uid 70, memcached 11211, rabbitmq 999, redis 999 — all four backing services confirmed healthy without root | Zulip container itself runs root for the init phase, drops every long-running worker to uid 1000 via supervisor |
| Privileges | `security_opt: no-new-privileges` everywhere | Setuid binaries can't gain caps mid-process |
| IPC | `ipc: private` on all containers | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 300` (pg) / `100` (memcached) / `300` (rabbitmq) / `100` (redis) / `1024` (zulip) | Caps fork sprawl; Zulip has a high budget because supervisor spawns ~25 worker processes |
| Two-network split | `zulip-db` created with `--internal` | Backing services have no internet egress; only the Zulip server has it via `zulip-front` |
| Port exposure | `127.0.0.1:8080` only | Only the reverse proxy can reach Zulip |
| Backend auth | Each backing service has its own password; no trust-network shortcuts | Compromise of one service doesn't auto-grant others |
| Healthchecks | `pg_isready` / `nc` / `rabbitmq-diagnostics` / `redis-cli` / `curl /health` | Built-in checks only; passwords passed via env to redis-cli (not visible in process list) |
| No Watchtower labels | Pinned image versions only | Reproducible upgrades; no silent moves |

### Why does Zulip's server container still run root?

Upstream's image is built around supervisord. The PID-1 entrypoint does the work of (a) chowning the data volume on first boot, (b) running cp/rm under `/etc/zulip/`, and (c) `su zulip -c` to drop migrations and long-running workers to uid 1000. Those operations need CHOWN/SETUID/SETGID/DAC_OVERRIDE/FOWNER in the namespace.

What's contained is still a lot: `cap_drop: ALL` removes every NET/SYS capability except `NET_BIND_SERVICE` for nginx, `no-new-privileges` prevents setuid escalation, the `zulip-db` network is `--internal`, and ulimits + pids keep one runaway worker from starving the host.

If you want stricter, you can run Zulip on a [user namespace](https://docs.docker.com/engine/security/userns-remap/) — see Docker's `userns-remap`. That fully de-maps in-container root to a low-privilege host uid.

### Why `zulip/zulip-postgresql:14` and not `postgres:18.4`?

Zulip server pins a specific postgres major in its puppet manifests (currently 14) and requires the **pgroonga** full-text search extension plus **tsearch_extras** to be present in the cluster. Upstream's `zulip/zulip-postgresql:14` image is the only one known to satisfy that contract. We still cap-drop, run it non-root (uid 70), and confine it to the `--internal` `zulip-db` network. The image is published by the Zulip core team from [zulip/zulip-postgresql](https://github.com/zulip/zulip-postgresql).

When Zulip's server moves to postgres 15+ upstream, this template will follow.

### Reverse-proxy TLS handoff

`ZULIP_HTTP_ONLY=True` (the default in this template) makes Zulip serve plain HTTP on its internal :80 and trust `X-Forwarded-Proto` from `LOADBALANCER_IPS`. Set both correctly and Zulip will:

- generate `https://` URLs in email/notification links,
- mark session cookies as Secure,
- redirect any browser request that doesn't carry `X-Forwarded-Proto: https`.

If `LOADBALANCER_IPS` is wrong, you'll see infinite redirect loops or `http://` links in emails — the [Zulip reverse proxy docs](https://zulip.readthedocs.io/en/latest/production/deployment.html#configuring-zulip-to-trust-proxies) cover the exact symptoms.

### Push notifications and telemetry

Mobile push notifications and usage statistics are **disabled by default**. Both are opt-in through the Zulip mobile-push service:

```bash
docker exec -it zulip-server bash -lc \
  '/home/zulip/deployments/current/manage.py register_server'
```

Then add `SETTING_ZULIP_SERVICE_PUSH_NOTIFICATIONS: "True"` to the `zulip` service's environment block. See [zulip.readthedocs.io/.../mobile-push-notifications.html](https://zulip.readthedocs.io/en/latest/production/mobile-push-notifications.html).

## Support the Project

- ⭐ [Star on GitHub](https://github.com/zulip/zulip)
- 💵 [Sponsor on GitHub](https://github.com/sponsors/zulip)
- 💬 [Community Chat](https://chat.zulip.org/)
- 📖 [Documentation](https://zulip.readthedocs.io/)

## License

Zulip is released under the [Apache-2.0 License](https://github.com/zulip/zulip/blob/main/LICENSE).
