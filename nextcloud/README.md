# Nextcloud

<p align="center">
  <img src="https://nextcloud.com/media/nextcloud-logo.svg" alt="Nextcloud Logo" width="300">
</p>

<p align="center">
  <a href="https://nextcloud.com/">Website</a> •
  <a href="https://docs.nextcloud.com/">Documentation</a> •
  <a href="https://github.com/nextcloud/server">GitHub</a> •
  <a href="https://help.nextcloud.com/">Community</a>
</p>

---

[Nextcloud](https://nextcloud.com/) is an open-source file-sync and collaboration platform — files, calendars, contacts, mail, video calls, office, the lot. A self-hosted alternative to Dropbox, Google Workspace, and Microsoft 365.

This template replaces the old `nextcloud-aio` mastercontainer setup with a vanilla **5-service compose** that gets the full hardening treatment used by the rest of this repo. AIO was removed because its docker-socket-mount + bundled-Watchtower design fundamentally conflicts with the "secure by default" stance — see [Why not AIO?](#why-not-nextcloud-aio) below.

## Features

- **File sync + share** — Desktop, iOS, Android clients; WebDAV; public links with expiry/passwords
- **Calendar, Contacts, Mail** — Built-in personal organizer apps
- **Collaborative editing** — Real-time docs/spreadsheets (Collabora / OnlyOffice add-on)
- **Video calls** — Nextcloud Talk add-on
- **End-to-end encryption** — Server-side or client-side, per-folder
- **App ecosystem** — 200+ apps in the Nextcloud App Store
- **Self-hosted** — Your data, your hardware, your rules

## Prerequisites

- Docker and Docker Compose
- Two external Docker networks (`nextcloud-front`, `nextcloud-db`)
- Reverse proxy (Caddy, Nginx, Traefik) for public TLS
- A domain name with DNS configured

## Quick Start

### 1. Create Docker Networks

One of two is `--internal` (no internet egress for postgres + redis):

```bash
docker network create nextcloud-front
docker network create --internal nextcloud-db
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

The `.env.example` file has `openssl` recipes next to each critical secret. The five that matter most:

- `POSTGRES_PASSWORD` — superuser, used only for init. `openssl rand -base64 36 | tr -d '\n'`.
- `POSTGRES_NON_ROOT_PASSWORD` — the password Nextcloud actually uses. Same generator.
- `REDIS_PASSWORD` — defense in depth even on an internal network. Same generator.
- `NEXTCLOUD_ADMIN_PASSWORD` — first-boot admin password. `openssl rand -base64 24`.
- `NEXTCLOUD_TRUSTED_DOMAINS` — comma-separated hostnames Nextcloud accepts requests for. **Without this, you get "Access through untrusted domain" on first login.**

Also set `OVERWRITEHOST` and `OVERWRITECLIURL` to your reverse-proxy URL so download links and federation handshakes use the right scheme/host.

### 3. Create Data Directories

```bash
mkdir -p data/{postgres,redis,nextcloud}
```

The postgres user is `${PUID}:${PGID}` (default 1000:1000) — it should already match your host user. The redis container picks up its own UID. The `data/nextcloud` directory is initialized by the app container's first-boot install.

### 4. Deploy

```bash
docker compose up -d
```

First boot installs Nextcloud (creates DB schema, copies files into `data/nextcloud`, runs initial setup) — takes about 2 minutes. Watch progress with `docker compose logs -f app`. The `nginx` service flips to `healthy` once `/status.php` returns 200 (full stack is up).

### 5. Log In

Open `https://cloud.example.com` (or whatever your reverse proxy serves) and log in with the `NEXTCLOUD_ADMIN_USER` / `NEXTCLOUD_ADMIN_PASSWORD` you set in `.env`.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `POSTGRES_USER` | Postgres superuser (init only) | Yes |
| `POSTGRES_PASSWORD` | Postgres superuser password | Yes |
| `POSTGRES_DB` | Database name | No (default `nextcloud`) |
| `POSTGRES_NON_ROOT_USER` | Nextcloud's DB user (least privilege) | Yes |
| `POSTGRES_NON_ROOT_PASSWORD` | Nextcloud DB user password | Yes |
| `REDIS_PASSWORD` | Redis `requirepass` | Yes |
| `NEXTCLOUD_ADMIN_USER` | First-boot admin username | Yes |
| `NEXTCLOUD_ADMIN_PASSWORD` | First-boot admin password | Yes |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Comma-separated hostnames | Yes |
| `OVERWRITEPROTOCOL` | `https` when behind a TLS-terminating proxy | No (default `https`) |
| `OVERWRITEHOST` | Public hostname (matches reverse proxy) | No |
| `OVERWRITECLIURL` | Public URL for occ-cli | No |
| `TRUSTED_PROXIES` | IPs/CIDRs allowed to set `X-Forwarded-*` | No (default safe CIDRs) |
| `NEXTCLOUD_PORT` | Host port (127.0.0.1 only) | No (default 8081) |
| `SMTP_*` | Outbound email settings | No |
| `OBJECTSTORE_S3_*` | S3/MinIO primary object store | No |
| `PUID` / `PGID` | Host UID/GID for postgres | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

Full [Nextcloud docker env reference](https://github.com/nextcloud/docker#environment-variables).

### Reverse Proxy (Caddy)

```caddyfile
cloud.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:8081
    header Strict-Transport-Security "max-age=31536000; includeSubDomains"

    # Nextcloud DAV redirects for client autodetect.
    redir /.well-known/carddav /remote.php/dav 301
    redir /.well-known/caldav  /remote.php/dav 301
}
```

The internal Nextcloud nginx listens on `127.0.0.1:8081` (set via `NEXTCLOUD_PORT`).

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8081 | HTTP | Web interface (reverse-proxy target) |

## Data Persistence

| Path | Description |
|------|-------------|
| `./data/postgres`   | PostgreSQL 18 datadir |
| `./data/redis`      | Redis snapshots (sessions, file locks, cache) |
| `./data/nextcloud`  | Nextcloud install + user files + apps + config |

The `./data/nextcloud` directory is bind-mounted **read-write** in `app` and `cron`, and **`:ro`** in `nginx` (nginx only serves static files — never writes).

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` on all 5 services. **postgres / redis / nginx have zero `cap_add`** (verified by test, May 2026); **app + cron have 4** (CHOWN/SETUID/SETGID/DAC_OVERRIDE — needed by the upstream entrypoint to install Nextcloud as root before dropping to www-data) | No NET_*/SYS_* caps anywhere in the stack |
| Non-root | postgres `${PUID}:${PGID}` (default 1000), redis 999:1000, nginx 101:101 — all three non-app services run truly non-root | app + cron run root in-container for the install/cron supervisor, drop long-running php to www-data (uid 33) |
| Privileges | `security_opt: no-new-privileges` on every container | Setuid binaries can't gain caps mid-process |
| IPC | `ipc: private` on every container | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 300` (pg) / `100` (redis) / `500` (app) / `100` (nginx) / `100` (cron) | Caps fork sprawl |
| Two-network split | `nextcloud-db` created with `--internal` | postgres + redis have no internet egress; only app/nginx/cron get out via `nextcloud-front` |
| Port exposure | `127.0.0.1` only on 8081 | Only the reverse proxy can reach Nextcloud |
| DB user | App connects as `POSTGRES_NON_ROOT_USER` from `init-data.sh` | App never has Postgres superuser |
| Postgres auth | `SCRAM-SHA-256` (`POSTGRES_HOST_AUTH_METHOD`) | Stronger than the default md5 |
| Redis auth | `--requirepass` + `REDISCLI_AUTH` for the healthcheck | No credentials in the process list |
| `nginx` listener | Unprivileged port 8080 inside the container | Lets nginx run as uid 101 with zero caps (no `NET_BIND_SERVICE` needed) |
| Static files `:ro` | `data/nextcloud` mounted read-only in nginx | nginx can serve but cannot modify user files |
| Healthchecks | `pg_isready` (pg) / `redis-cli ping` (redis) / `/status.php` (nginx) | Whole-stack health probed via the public-facing endpoint |

## Why not Nextcloud AIO?

This repo previously shipped a `nextcloud-aio` template. AIO was removed (May 2026) because its design conflicts with the security stance of every other template here:

1. **AIO requires `/var/run/docker.sock` to be mounted into the mastercontainer.** That gives the AIO container effective host-root: any compromise (or auth bypass in AIO's admin UI) lets an attacker `docker run --privileged -v /:/host` and own the host. The `:ro` on the socket mount is cosmetic — Docker's UNIX socket protocol honors write API calls through a `:ro`-flagged bind mount.
2. **AIO bundles its own Watchtower** for self-updating the subcontainers it spawns. We removed Watchtower from this repo in May 2026 because we use Dockhand for container management. AIO would silently put Watchtower back the moment you click "Start containers" in its UI.
3. **AIO spawns ~10 subcontainers under its own control** (Apache, Postgres, Redis, Talk, Collabora, ClamAV, Fulltextsearch, Imaginary, Notify_push, BorgBackup). Their security settings (caps, networks, resource limits) are decided by AIO, not by us — so the hardening we apply to the compose ends at the mastercontainer.

The vanilla compose here gives up AIO's conveniences — one-click backup setup (Borg), integrated update wizard, app-store install button — in exchange for actual hardening you can read and reason about line by line. If you want Borg backup, run [borgmatic](https://torsion.org/borgmatic/) against `./data/`. If you want the update wizard, the upstream `nextcloud/docker` image's `upgrade` command does the same job.

## Optional Add-ons

These are documented but not enabled by default — add them when you need them.

### Collabora Online (real-time office docs)

Run `collabora/code` on the `nextcloud-front` network, then install the Nextcloud Office app and point it at the Collabora URL.

### Nextcloud Talk (video calls)

For Group conversations of more than ~6 people, run [`nextcloud/aio-talk`](https://github.com/nextcloud/all-in-one/blob/main/community-containers/talk/readme.md)'s standalone HPB image. Smaller calls work without it.

### Object storage backend

Set the `OBJECTSTORE_S3_*` env vars in `.env` to redirect user file storage to S3/MinIO instead of `./data/nextcloud/data`. Existing files will need migration via `occ files:transfer-ownership`.

## Operations

### Run occ commands

```bash
docker exec -u www-data nextcloud-app php /var/www/html/occ status
docker exec -u www-data nextcloud-app php /var/www/html/occ user:add jane
```

### Backup

Stop the stack, snapshot `./data/`, restart:

```bash
docker compose stop
tar --acls --xattrs -czvf nextcloud-backup-$(date +%Y%m%d).tar.gz data/
docker compose start
```

For online backups, [borgmatic](https://torsion.org/borgmatic/) against `./data/` + an `occ maintenance:mode --on / --off` hook is the upstream-recommended pattern.

### Upgrade

```bash
docker compose pull
docker compose up -d
```

The app container's entrypoint runs `occ upgrade` automatically when it detects a version bump.

## Support the Project

- ⭐ [Star on GitHub](https://github.com/nextcloud/server)
- 💵 [Enterprise Support](https://nextcloud.com/enterprise/)
- 💬 [Community Forum](https://help.nextcloud.com/)
- 🐛 [Report Issues](https://github.com/nextcloud/server/issues)

## License

Nextcloud is released under the [AGPL-3.0 License](https://github.com/nextcloud/server/blob/master/COPYING).
