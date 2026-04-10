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
| meshcentral | root | Needs write to `/opt/meshcentral` for runtime modules and certs |
| mongodb | `${PUID}:${PGID}` | DHI runtime, runs as host user with pre-owned data dirs |

### Minimal Capability Grants

| Service | Capabilities | Reason |
|---------|-------------|--------|
| meshcentral | `DAC_OVERRIDE`, `CHOWN`, `SETUID`, `SETGID` | Entrypoint manages permissions, cert generation, npm module installs |
| mongodb | **None** | Zero capabilities — DHI distroless runtime |

### Docker Hardened Images

MongoDB uses `dhi.io/mongodb:8.0-debian13` — a Docker Hardened Image with:
- Zero known CVEs
- Minimal attack surface (distroless runtime)
- CIS benchmark compliant
- Complete SBOM and SLSA Level 3 provenance
- Runs as non-root (`mongodb`, UID 999)

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

**Tailscale mode**: Web UI routes through the reverse proxy. Agents connect via Tailscale IP directly — traffic is encrypted by WireGuard (Tailscale) and MeshCentral TLS (cert-pinned). Agent traffic never touches the public internet.

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
| mongodb | Disabled (DHI runtime has no shell) | — |

MeshCentral's healthcheck covers the full stack — if MongoDB is down, MeshCentral's health endpoint will fail.

## Known Security Considerations

1. **Self-signed internal TLS**: MeshCentral uses self-signed certificates internally. The reverse proxy must skip TLS verification to the backend (`tls_insecure_skip_verify`). Public-facing TLS is handled by the reverse proxy with valid certificates.

2. **MongoDB healthcheck disabled**: The DHI runtime image has no shell. The MeshCentral healthcheck covers full stack health — if MongoDB is unreachable, MeshCentral will report unhealthy.

3. **First account registration**: `newAccounts` is set to `true` in the generated config to allow initial admin registration. After creating your account, set `"newAccounts": false` in `data/meshcentral-data/config.json` and restart to lock down registration.

4. **Tailscale agent connections**: When using `--tailscale`, agents connect via the Tailscale IP with double encryption (WireGuard + MeshCentral TLS with cert pinning). Ensure Tailscale ACLs restrict which devices can reach the RMM server on tcp:443. The `agentConfig` field should be verified against MeshCentral's config schema before large-scale deployment — test with a single agent first.
