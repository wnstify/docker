# Security Model

This deployment follows strict container hardening standards for production self-hosted environments.

## Container Hardening

### Applied to Every Container

| Control | Implementation |
|---------|---------------|
| Drop all capabilities | `cap_drop: ALL` |
| Prevent privilege escalation | `security_opt: no-new-privileges:true` |
| Isolate IPC namespace | `ipc: private` |
| Temporary filesystem | `tmpfs: /tmp` with size limits |
| Resource limits | `memory`, `cpus`, `pids` limits and reservations |
| Restart policy | `unless-stopped` |

### Non-Root Execution

| Service | User | Notes |
|---------|------|-------|
| meshcentral | root | Image entrypoint runs node as root; needs write to `/opt/meshcentral` for cert generation and runtime modules |
| mongodb | `${PUID}:${PGID}` | Official entrypoint detects non-root start and skips the root chown/gosu privilege drop |

### Minimal Capability Grants

Cap minimums were verified by iterative testing (May 2026) — each row
lists *only* what the service fails to start without.

| Service | Capabilities | Reason |
|---------|-------------|--------|
| meshcentral | `NET_BIND_SERVICE`, `DAC_OVERRIDE` | Bind port 443 + 80 inside container; write certs to bind-mount owned by host UID |
| mongodb | **None** | `user: ${PUID}:${PGID}` skips the entrypoint's chown/gosu dance — mongod exec's directly |

### Optional Upgrade — Docker Hardened Images

For deployments with a [Docker Hardened Images](https://dhi.io) subscription, swap `mongo:8.0.23` for `dhi.io/mongodb:8.0-debian13` for:
- Zero known CVEs (curated patch flow)
- Distroless runtime — no shell, smaller attack surface
- CIS benchmark compliant, full SBOM, SLSA Level 3 provenance
- Runs as non-root (`mongodb`, UID 999)

DHI requires a paid Docker subscription, so the public template defaults to the official `mongo` image to keep the deployment friction-free for everyone. The `mongosh`-based healthcheck must be disabled when switching to DHI (no shell in the runtime); MeshCentral's own healthcheck still covers full-stack health.

## Network Segmentation

```
mc-frontend  (bridge)         MeshCentral binds to host (127.0.0.1:4430)
mc-internal  (internal: true) MeshCentral <-> MongoDB only
```

| Service | frontend | internal |
|---------|----------|----------|
| meshcentral | X | X |
| mongodb | | X |

MongoDB is only reachable from MeshCentral via the internal network. No host ports, no internet access.

## Host Port Exposure

| Port | Binding | Service | Purpose |
|------|---------|---------|---------|
| 4430/tcp | `127.0.0.1` | MeshCentral | HTTPS web UI + agent connections (reverse proxy only) |

**Standard mode**: Agents and the web UI share port 443. Everything routes through the reverse proxy — no additional ports needed.

**Tailscale mode**: Web UI routes through the reverse proxy. Agents connect via the Tailscale IP directly — double encrypted by WireGuard (Tailscale) and MeshCentral TLS (cert-pinned). MeshCentral certs are generated for the Tailscale IP, WANonly mode disables LAN discovery. Agent traffic never touches the public internet.

## Authentication

| Service | Auth Method |
|---------|------------|
| MongoDB | Network isolation (internal-only Docker network, no host ports, no auth needed) |
| MeshCentral | Built-in user management with session encryption |

## Secret Management

| File | Permissions | Contents |
|------|------------|----------|
| `.env` | `chmod 600` | PUID/PGID, ports |
| `data/meshcentral-data/config.json` | default | MongoDB connection, encryption keys, session key |

### Secrets Generated

| Secret | Method | Purpose |
|--------|--------|---------|
| DB encryption key | `openssl rand -hex 32` | At-rest encryption of sensitive data |
| Session key | `openssl rand -hex 32` | User session signing |

### TLS Certificates

MeshCentral generates self-signed TLS certificates on first boot, stored in `data/meshcentral-data/`. The reverse proxy (Pangolin) handles public TLS termination with valid certificates.

## Resource Limits

| Service | Memory Limit | CPU Limit | PID Limit |
|---------|-------------|-----------|-----------|
| meshcentral | 1 GB | 1.0 | 200 |
| mongodb | 1 GB | 1.0 | 200 |

## Healthchecks

| Service | Check | Interval |
|---------|-------|----------|
| meshcentral | Node.js HTTPS request to `/health.ashx` | 30s |
| mongodb | `mongosh --eval "db.adminCommand('ping').ok"` | 10s |

MongoDB's `depends_on: condition: service_healthy` gates MeshCentral startup until mongo accepts queries. MeshCentral's own healthcheck then covers full-stack health — if MongoDB is unreachable, the HTTPS endpoint fails.

## Known Security Considerations

1. **Self-signed internal TLS**: MeshCentral uses self-signed certificates internally. The reverse proxy must skip TLS verification to the backend (`tls_insecure_skip_verify`). Public-facing TLS is handled by the reverse proxy with valid certificates.

2. **MongoDB has no auth**: Connection security relies on Docker network isolation — `mc-internal` is `internal: true` (no internet egress) and no port is bound to the host. Only the `meshcentral` container can reach it. Any tenant on the same Docker host with access to the `mc-internal` network would bypass this — keep the network exclusive to this compose project. If you want defense-in-depth, set `MONGO_INITDB_ROOT_USERNAME`/`MONGO_INITDB_ROOT_PASSWORD` and update `mongoDb` in `config.json` to `mongodb://user:pass@mongodb:27017/meshcentral?authSource=admin`.

3. **First account registration**: `newAccounts` is set to `true` in the generated config to allow initial admin registration. After creating your account, set `"newAccounts": false` in `data/meshcentral-data/config.json` and restart to lock down registration.

4. **Tailscale agent connections**: When using `--tailscale`, MeshCentral's `cert` is set to the Tailscale IP and `WANonly` is enabled. Agents connect directly over the tailnet with double encryption (WireGuard + MeshCentral TLS with cert pinning). Ensure Tailscale ACLs restrict which devices can reach the RMM server on tcp:443. Agent install commands must be grabbed from the Tailscale IP URL, not the domain — the cert hash is different.
