# Syncthing

<p align="center">
  <img src="https://syncthing.net/img/logo-horizontal.svg" alt="Syncthing Logo" width="200">
</p>

<p align="center">
  <a href="https://syncthing.net/">Website</a> •
  <a href="https://docs.syncthing.net/">Docs</a> •
  <a href="https://github.com/syncthing/syncthing">GitHub</a> •
  <a href="https://forum.syncthing.net/">Forum</a>
</p>

---

[Syncthing](https://syncthing.net/) is a free, open-source, continuous file-synchronization program. It syncs files between two or more devices in real time, peer-to-peer, with no central server and no cloud — your data never leaves the devices you own. All traffic is end-to-end encrypted (TLS) and devices are mutually authenticated.

## Features

- **Peer-to-peer** — no central server; devices talk to each other directly
- **End-to-end encrypted** — TLS between devices, each identified by a cryptographic device ID
- **Real-time sync** — changes propagate as they happen via filesystem watching
- **Versioning** — keep old copies of changed/deleted files (simple, staggered, or trash-can)
- **Selective sync** — share different folders with different sets of devices
- **Cross-platform** — Linux, macOS, Windows, BSD, Android

## Prerequisites

- Docker and Docker Compose
- One external Docker network (`syncthing-front`)
- Reverse proxy (Caddy, Pangolin, Traefik) for public TLS **and authentication** on the GUI
- A directory on the host to sync, writable by your `${PUID}:${PGID}`
- For best performance: the sync port forwarded on your router/firewall (optional — Syncthing relays through public relays if it is blocked)

## Quick Start

### 1. Create Docker Network

```bash
docker network create syncthing-front
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Required value:

- `SYNC_DIR` — absolute host path to the directory tree you want to sync (mounted as `/sync` inside the container)

### 3. Deploy

```bash
mkdir -p data
docker compose up -d
```

`./data` holds Syncthing's config and index database and must be owned by your `${PUID}:${PGID}` (creating it as your normal user satisfies the default `1000:1000`).

### 4. Secure the GUI — do this before exposing it

A fresh Syncthing has **no GUI password**, and the GUI *is* the full admin/REST API. The compose binds it to `127.0.0.1` only, so reach it for first-time setup via an SSH tunnel:

```bash
ssh -L 8384:127.0.0.1:8384 you@your-server
# then open http://127.0.0.1:8384 in your local browser
```

In the GUI: **Actions → Settings → GUI**, set a username and password (and keep "Use HTTPS for GUI" enabled). Only then put it behind your reverse proxy. If you front it with SSO (Authentik/Pangolin), enforce auth at the proxy as well.

### 5. Pair a Device and Share a Folder

1. On each device: **Actions → Show ID** to get its device ID (or scan the QR code).
2. On this instance: **Add Remote Device**, paste the other device's ID, accept the reciprocal prompt on the other side.
3. **Add Folder** → set the folder path to `/sync/<name>` → under **Sharing**, tick the paired device.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `SYNC_DIR` | Absolute host path mounted as `/sync` | Yes |
| `SYNCTHING_GUI_PORT` | GUI host port (127.0.0.1 only) | No (default 8384) |
| `SYNCTHING_SYNC_PORT` | BEP sync port, TCP + UDP, all interfaces | No (default 22000) |
| `PUID` / `PGID` | Host UID/GID the container runs as | No (default 1000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

The image also honors `UMASK` and the full `STGUIADDRESS` / `ST*` family of Syncthing envs — add them under `environment:` if you need them. See the [upstream image README](https://hub.docker.com/r/syncthing/syncthing).

### Reverse Proxy (Caddy)

```caddyfile
syncthing.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:8384 {
        header_up Host {upstream_hostport}
    }
}
```

Syncthing checks the `Host` header against its CSRF protection, so pass `header_up Host {upstream_hostport}` (as above) to avoid "Host check" errors. Keep Syncthing's own GUI auth enabled even behind the proxy.

## Ports

| Port | Protocol | Binding | Description |
|------|---------|---------|-------------|
| 8384 | TCP | 127.0.0.1 only | Web GUI / REST API (reverse-proxy target) |
| 22000 | TCP + UDP | All interfaces | BEP sync protocol (peers connect inbound; UDP = QUIC) |
| 21027 | UDP | *unpublished* | LAN broadcast discovery — commented out (does not traverse the Docker bridge usefully) |

The sync port should be reachable from the internet for **direct** device connections — forward it in your router and host firewall. If it is blocked, Syncthing still works through public relay servers, just slower; relayed traffic remains end-to-end encrypted.

## Data Persistence

| Path | Description |
|------|-------------|
| `./data` | Syncthing home: `config/` (config.xml, device cert + key) and the SQLite index database |
| `${SYNC_DIR}` | Your synced files — written through to the host under `/sync` |

**Back up `./data`** — it contains the device's private key. Losing it changes the device ID, and every paired device will need to re-accept this one.

## Security Features

This template ships with a hardened default configuration:

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL`, **zero `cap_add`** | No Linux capabilities granted; all listen ports are unprivileged |
| Non-root | Compose `user: ${PUID}:${PGID}` (default 1000) | Entrypoint takes its non-root branch — plain `exec`, no setcap/chown/su-exec |
| Privileges | `security_opt: no-new-privileges` | Setuid binaries cannot gain caps |
| IPC | `ipc: private` | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` | Caps fork sprawl |
| GUI exposure | `127.0.0.1` only on the GUI host port | Only the reverse proxy can reach the admin/REST API |
| Data isolation | Synced files under `/sync`, config/keys under `/var/syncthing` | A misconfigured folder can't expose Syncthing's own keys |
| Healthcheck | `curl /rest/noauth/health` | Boot gated by an HTTP listener check |
| Image | Upstream-official `syncthing/syncthing`, not LSIO | Patched in lockstep with releases; no s6-overlay wrapper |

### Why the upstream-official image, not LinuxServer.io?

- **Published by The Syncthing Project directly**
- **Single-process container** — `syncthing` is PID 1 (via a thin entrypoint), no s6-overlay init layer
- **Patched in lockstep** with Syncthing releases
- **Multi-arch** (`amd64`, `arm64`, `arm`, `386`, `riscv64`)

> **Note on Syncthing 2.x:** version 2.0 replaced the old LevelDB index with SQLite. A fresh deployment (this template) is unaffected. If you are migrating an existing **1.x** `./data` directory, Syncthing performs a one-time automatic database migration on first start of 2.x — read the [v2 upgrade notes](https://docs.syncthing.net/) and back up `./data` first.

## Recommended In-App Settings

- **Settings → GUI**: set username + password; keep "Use HTTPS for GUI" on
- **Settings → Connections**: leave "Global Discovery" and "Relaying" on for NAT traversal; "Local Discovery" can be off in a server/Docker context
- **Per folder → File Versioning**: enable (Staggered is a good default) so an accidental delete on one device is recoverable
- **Per folder → Ignore Patterns**: exclude caches/temp dirs you don't want synced
- **Settings → General**: leave anonymous usage reporting at your discretion

## Support the Project

- [Star on GitHub](https://github.com/syncthing/syncthing)
- [Donate](https://syncthing.net/donations/)
- [Forum](https://forum.syncthing.net/)
- [Documentation](https://docs.syncthing.net/)

## License

Syncthing is released under the [MPL-2.0 License](https://github.com/syncthing/syncthing/blob/main/LICENSE).
