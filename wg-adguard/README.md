# WireGuard + AdGuard Home

<p align="center">
  <img src="https://www.wireguard.com/img/wireguard.svg" alt="WireGuard Logo" width="300">
</p>

<p align="center">
  <a href="https://www.wireguard.com/">WireGuard</a> •
  <a href="https://github.com/wg-easy/wg-easy">WG-Easy</a> •
  <a href="https://adguard.com/en/adguard-home/overview.html">AdGuard Home</a> •
  <a href="https://github.com/AdguardTeam/AdGuardHome">AdGuard GitHub</a>
</p>

---

A self-hosted VPN stack: **WireGuard** (via WG-Easy) for the tunnel, **AdGuard Home** for network-wide DNS filtering. Connect from anywhere, browse with ads blocked, regardless of which network you're on.

## Architecture

```
                              VPN clients
                              10.8.0.0/24
                                  │
                          UDP 51820 │
                                  ▼
┌─────────────────────────────────────────────────────┐
│  vpn_net (Docker bridge, 10.0.0.0/24)               │
│                                                      │
│   ┌──────────────┐  DNS:53  ┌──────────────────┐    │
│   │   AdGuard    │◄─────────┤     WG-Easy      │    │
│   │   Home       │          │   (WireGuard)    │    │
│   │  10.0.0.100  │          │   10.0.0.200     │    │
│   └──────────────┘          └──────────────────┘    │
└─────────────────────────────────────────────────────┘
         │  ▲                           │  ▲
         │  └─ 127.0.0.1:8080 (admin)   │  └─ 127.0.0.1:51821 (admin)
         │                              │
         │                              └─ 0.0.0.0:51820/udp (public VPN)
         │
         └─ no host DNS port — clients reach :53 via vpn_net only
```

- **Docker network** `10.0.0.0/24` — internal communication between containers
- **VPN tunnel** `10.8.0.0/24` — what clients get as their tunnel address (must NOT overlap the docker network)

## Prerequisites

- Docker and Docker Compose v2+
- A host with a static public IP (or dynamic DNS)
- **UDP/51820** open in your router/firewall (or whatever you set `WG_PORT` to)
- A reverse proxy (Caddy, Nginx, Traefik, Pangolin) if you want to expose the web UIs publicly with TLS

### Host-side prep

WireGuard + iptables-legacy NAT need kernel modules. Either the kernel has them built in (`CONFIG_WIREGUARD=y`) or they're loadable modules that need to be loaded. The container can self-load them with `SYS_MODULE` + `/lib/modules:ro`, but you can also pre-load on the host so it survives reboots:

```bash
sudo modprobe wireguard iptable_nat
echo wireguard | sudo tee /etc/modules-load.d/wireguard.conf
echo iptable_nat | sudo tee /etc/modules-load.d/iptable_nat.conf
```

## Quick Start

### 1. Generate the WG-Easy admin password hash

WG-Easy stores its admin password as a bcrypt hash. Generate one with the image's own bundled bcryptjs:

```bash
docker run --rm ghcr.io/wg-easy/wg-easy:15.3.0 node -e \
  'console.log(require("bcryptjs").hashSync(process.argv[1], 10))' \
  'YOUR-STRONG-PASSWORD'
```

Copy the output. **In your `.env`, double-escape every `$` as `$$`** — docker compose interpolation eats single `$`.

### 2. Configure environment

```bash
cp .env.example .env
nano .env
```

Set `WG_HOST` (your public IP or DNS name) and paste the escaped `PASSWORD_HASH`.

### 3. Deploy

```bash
docker compose up -d
```

### 4. AdGuard initial setup

Open `http://127.0.0.1:3000` (or the `ADGUARD_SETUP_PORT` you configured) and run the setup wizard:

- DNS listen interface: leave as default (binds inside the container)
- Web admin interface: leave on port 80 (the wizard's port 3000 redirects to it after setup)
- Set an admin username + password
- Recommended upstream DNS: `https://dns.quad9.net/dns-query` (DoH) or `https://dns.cloudflare.com/dns-query`

After setup, the dashboard moves to `http://127.0.0.1:8080`.

### 5. WG-Easy: create your first client

Open `http://127.0.0.1:51821`, log in with the password you bcrypt-hashed, click **New Client**, scan the QR code on a phone or download the `.conf` for a desktop. Done.

## Configuration

### Environment Variables

| Variable | Description | Required |
|---|---|---|
| `WG_HOST` | Public IP / DNS name VPN clients dial in to | Yes |
| `PASSWORD_HASH` | bcrypt-hashed admin password for the WG-Easy UI (with `$` doubled) | Yes |
| `WG_DEFAULT_ADDRESS` | CIDR pattern for client IPs (must not overlap docker `vpn_net`) | No (default `10.8.0.x`) |
| `WG_DEFAULT_DNS` | DNS server pushed to clients | No (default `10.0.0.100`, AdGuard) |
| `WG_ALLOWED_IPS` | What clients can reach via the tunnel | No (default `0.0.0.0/0, ::/0`) |
| `WG_PORT` | Public UDP listen port | No (default 51820) |
| `WG_UI_PORT` | Host port for WG-Easy admin (127.0.0.1 only) | No (default 51821) |
| `ADGUARD_UI_PORT` | Host port for AdGuard dashboard | No (default 8080) |
| `ADGUARD_SETUP_PORT` | Host port for AdGuard setup wizard | No (default 3000) |
| `TZ` | Container timezone | No (default `Europe/Bratislava`) |

### Reverse Proxy (Caddy)

```caddyfile
vpn.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:51821
}

adguard.example.com {
    encode zstd gzip
    reverse_proxy http://127.0.0.1:8080
}
```

Both admin UIs are bound to `127.0.0.1` so they're only reachable through the proxy.

## Ports

| Port | Proto | Service | Binding | Purpose |
|------|-------|---------|---------|---------|
| 51820 | UDP | WG-Easy | All interfaces | WireGuard VPN tunnel (clients connect here) |
| 51821 | TCP | WG-Easy | 127.0.0.1 | WG-Easy web UI |
| 8080  | TCP | AdGuard | 127.0.0.1 | AdGuard dashboard (post-setup) |
| 3000  | TCP | AdGuard | 127.0.0.1 | AdGuard setup wizard (initial) |

DNS port 53 is **not** exposed to the host — clients reach it via the docker `vpn_net` at `10.0.0.100:53` once they're connected to the tunnel.

## Data Persistence

| Path | Description |
|------|-------------|
| `./config`  | AdGuard config + filter lists + query log |
| `./wg-easy` | WireGuard server keys + per-client configs |

Back these up — losing `./wg-easy` invalidates every client config.

## Security Features

| Layer | Setting | Effect |
|---|---|---|
| Capabilities | `cap_drop: ALL` on both services. **adguard** adds 2 (`NET_BIND_SERVICE`, `DAC_OVERRIDE`); **wg-easy** adds 3 (`NET_ADMIN`, `SYS_MODULE`, `NET_RAW`) | Each cap is required by a specific syscall, verified by trim-and-retest |
| Why root in containers | AdGuard refuses to run non-root on first launch (the "must run as administrator" error). WG-Easy needs root to manipulate network namespaces and iptables rules | Both containers run root *with* `no-new-privileges` *and* the tightest cap set possible — the alternative (privileged) would be far worse |
| Privileges | `security_opt: no-new-privileges` on every container | Setuid binaries can't gain caps mid-process |
| IPC | `ipc: private` on every container | Isolated SysV/POSIX IPC namespace |
| Process budget | `pids: 200` on both | Caps fork sprawl |
| Port exposure | Admin UIs on `127.0.0.1` only (reverse-proxy targets); DNS port 53 not exposed to host at all | Only the VPN tunnel can reach DNS |
| Secret hygiene | `WG_HOST` + `PASSWORD_HASH` read from `.env`, never inlined in the compose | Previous template hard-coded a public IP into git — fixed |
| Healthchecks | wget probes on both web UIs | Surfaces crashloops in `docker compose ps` |
| Module mount | `/lib/modules:/lib/modules:ro` on wg-easy | Container can load kernel modules but can never modify the host's module library |

## Operations

### View VPN client traffic

WG-Easy's dashboard shows real-time bytes in/out per client and the time of last handshake. Useful for spotting clients that haven't connected in a while.

### Check that DNS filtering is working

1. Connect to the VPN
2. Visit `https://www.dnsleaktest.com/` — should show only AdGuard
3. Visit `https://adblock-tester.com/` — should report 100% blocked
4. AdGuard dashboard → **Query log** shows the blocks in real time

### Upgrade

```bash
docker compose pull
docker compose up -d
```

The image tags here are pinned to specific patch versions — set new versions in `docker-compose.yml` and re-run the above.

### Reset the WG-Easy admin password

Generate a new bcrypt hash (see Quick Start step 1), replace `PASSWORD_HASH` in `.env`, then:

```bash
docker compose up -d
```

The change picks up on container recreate without losing client configs.

## Troubleshooting

**"Permission denied (you must be root)" from wg-quick:** the host kernel doesn't have the iptables-legacy NAT module available, and `SYS_MODULE` + `/lib/modules:ro` aren't enough to load it. Run `sudo modprobe iptable_nat` on the host once.

**WireGuard module fails to load:** check `lsmod | grep wireguard`. If empty, `sudo modprobe wireguard`. If `modprobe` says "module not found", your kernel doesn't have WireGuard — check `grep CONFIG_WIREGUARD /boot/config-$(uname -r)`. Modern Debian/Ubuntu/Fedora kernels (≥5.6) all have it.

**"This is the first launch of AdGuard Home; you must run it as administrator":** that's AdGuard refusing to start non-root on first boot. The compose handles this correctly (runs as root with `cap_drop: ALL` + minimal `cap_add`). If you see this, your bind-mount permissions are wrong — delete `./config/*` and let the container regenerate.

**Connected to VPN but no internet:** check `WG_DEFAULT_DNS` resolves to AdGuard's IP (`10.0.0.100` by default) and that `net.ipv4.ip_forward=1` is in the wg-easy sysctls (it is by default in this compose). Use `docker exec wg-easy wg show` to confirm a handshake.

## Resources

- **Setup walkthrough:** [Definitive Self-Hosting Guide](https://youtu.be/tTyq9xGy1pM)
- **WireGuard Official:** [wireguard.com](https://www.wireguard.com/)
- **WG-Easy:** [github.com/wg-easy/wg-easy](https://github.com/wg-easy/wg-easy)
- **AdGuard Home:** [github.com/AdguardTeam/AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)

## License

- **WireGuard** — GPL-2.0
- **WG-Easy** — see the [upstream repo](https://github.com/wg-easy/wg-easy)
- **AdGuard Home** — GPL-3.0
