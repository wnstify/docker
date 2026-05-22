![Webnestify Logo](https://webnestify.cloud/wp-content/uploads/2023/11/webnestify-logo-dark-300x109.png)

# Webnestify Docker Project Templates

[![GitHub Stars](https://img.shields.io/github/stars/wnstify/docker?style=flat-square)](https://github.com/wnstify/docker/stargazers)
[![GitHub License](https://img.shields.io/github/license/wnstify/docker?style=flat-square)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/wnstify/docker?style=flat-square)](https://github.com/wnstify/docker/commits/main)
[![OpenSSF Scorecard](https://img.shields.io/ossf-scorecard/github.com/wnstify/docker?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/wnstify/docker)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/12931/badge)](https://www.bestpractices.dev/projects/12931)

Production-ready Docker Compose templates for self-hosting open-source applications. Every template is hardened to a uniform baseline — `cap_drop: ALL` with the minimum verified `cap_add`, `no-new-privileges`, `ipc: private`, internal-only Docker networks for database tiers, pinned image versions, healthchecks, and per-container resource limits. The current CVE state of every image is published in [AUDIT.md](AUDIT.md).

---

## Table of Contents

- [Available Templates](#available-templates)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Common Configuration](#common-configuration)
- [Security Features](#security-features)
- [Security Audit](#security-audit)
- [Releases & Verification](#releases--verification)
- [About Webnestify](#about-webnestify)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## Available Templates

### Productivity & Automation

| Template | Description |
|---|---|
| [n8n](./n8n) | Workflow automation (Zapier alternative). Postgres 18, Redis, dedicated task runner |
| [Baserow](./baserow) | No-code database (Airtable alternative). Postgres 18 |
| [DocuSeal](./docuseal) | Document signing and forms. Postgres 18, bundled Gotenberg |
| [Nextcloud](./nextcloud) | File sync + collaboration. Postgres 18, Redis, FPM + nginx, cron |

### Media & Entertainment

| Template | Description |
|---|---|
| [Jellyfin](./jellyfin) | Free media server for movies, TV, and music |
| [Navidrome](./navidrome) | Self-hosted music server (Subsonic/Airsonic compatible) |
| [qBittorrent](./qbittorrent) | BitTorrent client with web UI |

### Infrastructure & Operations

| Template | Description |
|---|---|
| [Dockhand](./dockhand) | Docker management UI with free SSO (Portainer alternative). Postgres + docker-socket-proxy |
| [Uptime Kuma](./uptime-kuma) | Self-hosted monitoring + status pages. MariaDB backend |
| [MeshCentral](./meshcentral) | Remote monitoring & management (RMM). Vanilla MongoDB 8.0 |
| [WireGuard + AdGuard](./wg-adguard) | WireGuard VPN (wg-easy) with AdGuard Home DNS filtering |

### Identity & Security

| Template | Description |
|---|---|
| [Authentik](./authentik) | Identity provider with SSO, OAuth2, SAML, LDAP. Postgres 18 (Redis dropped in 2025.10+) |

### Communication & Collaboration

| Template | Description |
|---|---|
| [Stoat](./stoat) | Self-hosted Discord alternative with voice/video (formerly Revolt) |
| [Zulip](./zulip) | Threaded team chat (Slack alternative). Postgres 18, Memcached, RabbitMQ, Redis |
| [Open WebUI](./openwebui) | Web interface for LLMs (ChatGPT alternative) |

### Content & Information

| Template | Description |
|---|---|
| [FreshRSS](./freshrss) | Self-hosted RSS feed aggregator |
| [SerpBear](./serpbear) | SEO rank tracking |

---

## Prerequisites

- **Docker** v20.10 or higher
- **Docker Compose** v2.0 or higher
- A **reverse proxy** with TLS termination — [Caddy](https://caddyserver.com/) or [Pangolin](https://pangolin.fossorial.io/) is recommended. Every template's web UI binds to `127.0.0.1` and is intended to be fronted by the proxy.
- For each template: one or more **external Docker networks** that the compose file references. Each template's `README.md` documents the exact `docker network create` commands it needs (commonly one front-of-house network and one `--internal` network for the database tier).

---

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/wnstify/docker.git
   cd docker
   ```

2. **Pick a template and read its README**
   ```bash
   cd n8n && cat README.md
   ```
   Every template's README documents the exact Docker networks it needs, the required `.env` values, and any host-side prep (e.g., `modprobe wireguard` for the VPN stack).

3. **Create the networks the template needs**
   ```bash
   # Example (n8n): two networks, db tier internal-only
   docker network create n8n-front
   docker network create --internal n8n-db
   ```

4. **Configure environment**
   ```bash
   cp .env.example .env
   $EDITOR .env
   ```
   `.env.example` files include `openssl` recipes next to every secret. **Generate strong values** — most templates `:?` on missing required vars and refuse to start with placeholders.

5. **Deploy**
   ```bash
   docker compose up -d
   ```

6. **Front it with the reverse proxy** — every template binds to `127.0.0.1`, so the proxy is the only thing serving the web UI publicly.

---

## Directory Structure

```
docker/
├── README.md            # this file
├── SECURITY.md          # vulnerability reporting + security policy
├── AUDIT.md             # latest CVE scan of every image (Trivy)
├── LICENSE
│
├── authentik/           # SSO / IdP
├── baserow/             # no-code DB
├── dockhand/            # Docker management UI
├── docuseal/            # document signing
├── freshrss/            # RSS aggregator
├── jellyfin/            # media server
├── meshcentral/         # RMM
├── n8n/                 # workflow automation
├── navidrome/           # music server
├── nextcloud/           # files + collab (5-service vanilla stack)
├── openwebui/           # LLM web UI
├── qbittorrent/         # BitTorrent client
├── serpbear/            # SEO rank tracking
├── stoat/               # Discord-alternative chat
├── uptime-kuma/         # monitoring + status pages
├── wg-adguard/          # WireGuard VPN + AdGuard DNS
└── zulip/               # team chat
```

Every template directory contains at least `docker-compose.yml`, `.env.example`, and `README.md`. Some also ship an `init-data.sh` for non-root DB user creation or other small helpers — see each template's own README.

---

## Common Configuration

### Environment variables

Every template ships a tracked `.env.example` and an untracked `.env`. The example file has `openssl` recipes next to every secret it expects. **Never commit `.env`** — the repo's `.gitignore` already excludes it, but generate strong unique values and don't reuse the placeholders.

### Reverse proxy

All web UIs bind to `127.0.0.1` only — the reverse proxy is the only thing that serves them publicly. Caddy example:

```
your-domain.com {
    reverse_proxy http://127.0.0.1:5678
}
```

[Pangolin](https://pangolin.fossorial.io/) is the other recommended option if you want central auth + tunnels in front of multiple services.

### Container management & updates

We use [Dockhand](./dockhand) (with the `tecnativa/docker-socket-proxy` sidecar limiting socket exposure) for ongoing container management. Image updates are handled by `docker compose pull && docker compose up -d` against the pinned tags in each template's compose file — there's no Watchtower or other auto-pull mechanism in this repo.

### Database user creation

Templates that run their own Postgres (n8n, Baserow, DocuSeal, Nextcloud, authentik, zulip) ship an `init-data.sh` that creates a non-root application user on first boot. The compose's `POSTGRES_PASSWORD` is the superuser; the application connects as `POSTGRES_NON_ROOT_USER`. SCRAM-SHA-256 is forced via `POSTGRES_HOST_AUTH_METHOD`.

---

## Security Features

Every template ships with the same hardened baseline:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` with a minimum verified `cap_add` per role | Each capability earned its place via cap-trim testing. Most database/cache containers run with **zero** caps. |
| Privileges | `security_opt: no-new-privileges:true` | Setuid binaries can't gain caps mid-process |
| IPC | `ipc: private` | Isolated SysV / POSIX IPC namespace per container |
| Image tags | Specific patch versions, never `:latest` or floating major tags | Reproducible deploys; supply-chain pin |
| Network split | App tier on a regular bridge; DB / cache tier on an `--internal` bridge | Postgres / Redis / MongoDB / MariaDB have no internet egress |
| Public exposure | `127.0.0.1:<port>` bindings on every web UI | Only the reverse proxy can reach the admin endpoints |
| Resources | `deploy.resources.limits` for memory / cpus / pids on every service | DoS-class CVEs in any one container can't take down the host |
| Ephemeral writes | `tmpfs` for `/tmp`, `/var/cache/nginx`, etc. with `size=` caps | No persistence required; race-condition gadgets neutered |
| Auth | Postgres uses `SCRAM-SHA-256`; Redis uses `--requirepass` + `REDISCLI_AUTH`; non-root app DB user | Stronger than upstream defaults; credentials never appear in process list |
| Lifecycle | Healthchecks on every service with `start_period` matched to the slowest first-boot | `docker compose ps` is a true signal |
| Secrets | `.env.example` tracked, `.env` ignored; required vars use `${VAR:?error}` | Service fails fast if a secret is missing |

For security concerns or vulnerability reports, see our [Security Policy](SECURITY.md).

## Security Audit

[AUDIT.md](AUDIT.md) is a Trivy CVE scan of every image referenced in every compose file in this repo, triaged against the hardened configuration above. The audit is timestamped (image tags + scanner DB version + scan date), distinguishes findings that are exploitable in production from those neutered by the hardening, and lists exactly which CVE patterns were filtered as noise and why. It's regenerated each time the templates change materially.

Re-running it locally:

```bash
# Install Trivy (if not already installed)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

# Scan a single image
trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --scanners vuln <image>:<tag>
```

## Releases & Verification

Releases are tagged with [Calendar Versioning](https://calver.org/) (`YYYY.MM.DD`) and signed end-to-end:

- **Source archive** (`.tar.gz` + `.zip`) built from tracked files via `git archive`.
- **`SHA256SUMS`** covering both archives.
- **Sigstore keyless signature** (`SHA256SUMS.sigstore.json`) — bound to this repo's release workflow via short-lived OIDC certs (no long-lived private key to leak).
- **SLSA build-provenance attestation** for each archive — verifiable with `gh attestation verify`.

Notable changes appear on the [Releases page](https://github.com/wnstify/docker/releases), auto-generated from merged PRs. Each release tarball also includes a [CHANGELOG.md](CHANGELOG.md) snapshot. Copy-paste verification commands (cosign + `gh attestation verify`) are in [VERIFICATION.md](VERIFICATION.md). The release workflow itself: [`.github/workflows/release.yml`](.github/workflows/release.yml).

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

New templates must match the hardening baseline (see [Security Features](#security-features)). Concretely, each new template should include:

- `docker-compose.yml` with, for every service:
  - Pinned image tag (no `:latest`, no floating major)
  - `cap_drop: ALL` + the minimum `cap_add` that you've **verified** by trim-and-retest
  - `security_opt: [no-new-privileges:true]` and `ipc: private`
  - `deploy.resources.limits` covering `memory`, `cpus`, and `pids`
  - A working `healthcheck` with a `start_period` matched to the slowest first-boot
  - Web UIs bound to `127.0.0.1` only
  - Database / cache tier on an external `--internal` Docker network
- `.env.example` tracked, real `.env` git-ignored. Required vars use `${VAR:?error}` so the stack fails fast if you forget one.
- `README.md` documenting the exact networks to `docker network create`, the required `.env` values, and any host-side prep.
- Optional but recommended: `init-data.sh` for non-root DB user.

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