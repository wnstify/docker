# WireGuard + AdGuard Home VPN Stack

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

A secure, self-hosted VPN solution combining **WireGuard** (via WG-Easy) with **AdGuard Home** for network-wide ad blocking and DNS filtering. Connect to your VPN from anywhere and enjoy ad-free, private browsing on all your devices.

## Video Guide

For a complete walkthrough on setting up this stack with secure reverse proxy and authentication, watch our definitive guide:

[![Definitive Self-Hosting Guide](https://img.shields.io/badge/YouTube-Definitive_Self--Hosting_Guide_(2025)-red?style=for-the-badge&logo=youtube)](https://youtu.be/tTyq9xGy1pM)

**What you'll learn:**
- Setting up **Pangolin** as a reverse proxy with wildcard SSL and secure tunneled access
- Integrating **Authentik** for unified user management and SSO (optional but recommended)
- Creating private subnets for secure intra-server communication
- Protecting your apps with **CrowdSec** for 24/7 security
- Server setup on your own hardware or cloud providers like Hetzner

---

## Features

### WireGuard (WG-Easy)
- **Modern VPN Protocol** — Fast, secure, and lightweight
- **Easy Web UI** — Manage clients without command-line
- **QR Code Generation** — Instant mobile setup
- **Cross-Platform** — Works on Windows, macOS, Linux, iOS, Android
- **Persistent Connections** — Automatic reconnection on network changes

### AdGuard Home
- **Network-Wide Ad Blocking** — Block ads on all connected devices
- **DNS-over-HTTPS/TLS** — Encrypted DNS queries
- **Parental Controls** — Family-friendly filtering options
- **Query Logging** — Monitor DNS requests
- **Custom Blocklists** — Add your own filter lists
- **Safe Browsing** — Protection against malicious domains

### Combined Benefits
- **Privacy Everywhere** — VPN + ad blocking on any network
- **No Client Software Needed** — Ad blocking at DNS level
- **Single Stack** — Both services in one deployment
- **Automatic Updates** — Watchtower integration enabled

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Host                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  vpn_net (10.0.0.0/24)                      ││
│  │                                                              ││
│  │   ┌──────────────┐           ┌──────────────────┐           ││
│  │   │   AdGuard    │           │     WG-Easy      │           ││
│  │   │   Home       │◄──DNS────►│   (WireGuard)    │           ││
│  │   │              │           │                  │           ││
│  │   │  10.0.0.100  │           │   10.0.0.200     │           ││
│  │   └──────────────┘           └──────────────────┘           ││
│  │          │                            │                      ││
│  └──────────┼────────────────────────────┼──────────────────────┘│
│             │                            │                       │
│      :8080 (Web UI)              :51820/udp (VPN)               │
│      :3000 (Setup)               :51821 (Web UI)                │
│      localhost only              public + localhost              │
└─────────────────────────────────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │        Pangolin Proxy       │
                    │   (Wildcard SSL + Tunnel)   │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │    Authentik (Optional)     │
                    │      (SSO + User Mgmt)      │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │      VPN Clients         │
                    │      10.8.0.0/24         │
                    │  (10.8.0.2, 10.8.0.3...) │
                    └──────────────────────────┘
```

**Network Separation:**
- **Docker Network** (`10.0.0.0/24`): Internal communication between containers
- **VPN Tunnel** (`10.8.0.0/24`): IP range assigned to VPN clients

## Prerequisites

- Docker and Docker Compose v2.0+
- A server with a **static public IP** or dynamic DNS
- **UDP port 51820** open on your firewall/router
- **Pangolin** for secure reverse proxy with wildcard SSL
- **Authentik** for unified authentication (optional but recommended)

## Quick Start

### 1. Generate Password Hash

WG-Easy requires a bcrypt-hashed password. Generate one using:

```bash
docker run ghcr.io/wg-easy/wg-easy:14 node -e 'const bcrypt = require("bcryptjs"); const hash = bcrypt.hashSync("YOUR-PASSWORD", 10); console.log(hash.replace(/\$/g, "$$$$"));'
```

Replace `YOUR_PASSWORD` with your desired password. Copy the output hash.

### 2. Configure docker-compose.yml

Edit `docker-compose.yml` and update these values:

```yaml
# WG-Easy configuration
- WG_HOST=your.server.ip.or.domain    # Your public IP or domain
- PASSWORD_HASH=$$2a$$10$$...          # Your escaped bcrypt hash

# Optional: Adjust timezone
- TZ=Europe/Bratislava                 # Your timezone
```

### 3. Deploy the Stack

```bash
docker compose up -d
```

### 4. Configure AdGuard Home

1. Access AdGuard Home setup at `http://localhost:3000`
2. Complete the initial setup wizard
3. Configure upstream DNS servers (e.g., `1.1.1.1`, `8.8.8.8`, or DNS-over-HTTPS)
4. Add blocklists as needed

### 5. Access WG-Easy

1. Access WG-Easy at `http://localhost:51821`
2. Log in with your password
3. Create VPN clients and scan QR codes on mobile devices

### 6. Set Up Secure Access with Pangolin

For production deployments, secure your web UIs with Pangolin reverse proxy:

- **Wildcard SSL certificates** for all your self-hosted apps
- **Secure tunneled access** without exposing ports directly
- **Optional Authentik integration** for SSO and unified user management

Watch the complete setup guide: [Definitive Self-Hosting Guide (2025)](https://youtu.be/tTyq9xGy1pM)

## Configuration

### Environment Variables

#### AdGuard Home

| Variable | Description | Default |
|----------|-------------|---------|
| `PUID` | User ID for file permissions | `1000` |
| `PGID` | Group ID for file permissions | `1000` |
| `TZ` | Timezone | `Europe/Bratislava` |

#### WG-Easy

| Variable | Description | Required |
|----------|-------------|----------|
| `WG_HOST` | Public IP or domain for VPN connections | Yes |
| `PASSWORD_HASH` | Bcrypt hash for web UI (escaped) | Yes |
| `WG_DEFAULT_ADDRESS` | Client IP range pattern | `10.8.0.x` |
| `WG_DEFAULT_DNS` | DNS server for clients | `10.0.0.100` |
| `WG_ALLOWED_IPS` | IPs clients can access | `0.0.0.0/0, ::/0` |

### Network Configuration

The stack uses a custom bridge network with static IPs:

| Container | IP Address | Purpose |
|-----------|------------|---------|
| AdGuard Home | `10.0.0.100` | DNS server for VPN clients |
| WG-Easy | `10.0.0.200` | VPN server |

VPN clients receive IPs from `10.8.0.0/24` (10.8.0.2, 10.8.0.3, etc.).

## Ports

| Port | Protocol | Service | Binding | Description |
|------|----------|---------|---------|-------------|
| 51820 | UDP | WG-Easy | Public | WireGuard VPN tunnel |
| 51821 | TCP | WG-Easy | localhost | Web management UI |
| 8080 | TCP | AdGuard | localhost | Web dashboard |
| 3000 | TCP | AdGuard | localhost | Initial setup wizard |

**Note:** After initial AdGuard setup, port 3000 redirects to 8080.

## Data Persistence

| Path | Description |
|------|-------------|
| `./config` | AdGuard Home configuration and data |
| `./wg-easy` | WireGuard configuration and client keys |

**Backup these directories regularly!**

## Usage

### Adding VPN Clients

1. Open WG-Easy web UI
2. Click "New Client"
3. Enter a name (e.g., "iPhone", "Laptop")
4. Scan the QR code or download the configuration file
5. Import into WireGuard app on your device

### Managing Blocklists (AdGuard)

1. Open AdGuard Home dashboard
2. Go to **Filters** → **DNS Blocklists**
3. Add popular lists:
   - **AdGuard DNS filter** (included by default)
   - **OISD** — `https://big.oisd.nl`
   - **Steven Black** — `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`

### Checking DNS Filtering

1. Connect to VPN
2. Visit `https://adguard.com/test.html` to verify ad blocking
3. Check AdGuard dashboard for query logs

## Troubleshooting

### VPN Connection Issues

**Can't connect to VPN:**
1. Verify UDP port 51820 is open on firewall
2. Check `WG_HOST` matches your public IP or domain
3. Ensure client config was generated after server setup

**Connected but no internet:**
1. Verify `net.ipv4.ip_forward=1` is enabled on host
2. Check `WG_DEFAULT_DNS` points to AdGuard (`10.0.0.100`)
3. Ensure AdGuard container is running

```bash
# Check container status
docker compose ps

# View logs
docker compose logs wg-easy
docker compose logs adguard
```

### AdGuard Issues

**Can't access setup wizard:**
```bash
# Check if port 3000 is listening
docker compose logs adguard | grep -i listen
```

**DNS not working:**
1. Verify AdGuard is running on `10.0.0.100`
2. Test DNS resolution: `nslookup google.com 10.0.0.100`

### Password Issues

**Forgot WG-Easy password:**
1. Generate a new hash (see Quick Start)
2. Update `PASSWORD_HASH` in docker-compose.yml
3. Restart: `docker compose up -d`

**Password not working:**
- Ensure all `$` are escaped as `$$` in docker-compose.yml

## Security Considerations

- **Web UIs bound to localhost** — Only accessible via Pangolin reverse proxy
- **No-new-privileges enabled** — Prevents privilege escalation
- **Separate networks** — VPN clients isolated from Docker network
- **Automatic updates** — Watchtower labels enabled

### Recommended Security Stack

For serious self-hosters, we recommend the complete security stack:

| Component | Purpose |
|-----------|---------|
| **Pangolin** | Reverse proxy with wildcard SSL and secure tunnels |
| **Authentik** | SSO and unified user management across all apps |
| **CrowdSec** | Collaborative security with real-time threat detection |

Learn how to set up the complete stack: [Definitive Self-Hosting Guide (2025)](https://youtu.be/tTyq9xGy1pM)

### Best Practices

1. Use strong, unique passwords
2. Set up Pangolin for secure external access
3. Enable Authentik for unified authentication
4. Regularly update blocklists
5. Monitor AdGuard logs for anomalies
6. Backup configuration before updates

## Resources

- **Complete Setup Guide:** [Definitive Self-Hosting Guide (2025)](https://youtu.be/tTyq9xGy1pM)
- **Webnestify YouTube:** [@webnestify](https://youtube.com/@webnestify)
- **Discord Community:** [Join Discord](https://wnstify.cc/discord)

## Support the Projects

### WireGuard / WG-Easy
- [WireGuard Official](https://www.wireguard.com/)
- [WG-Easy GitHub](https://github.com/wg-easy/wg-easy)
- [WireGuard Donations](https://www.wireguard.com/donations/)

### AdGuard Home
- [AdGuard Home GitHub](https://github.com/AdguardTeam/AdGuardHome)
- [AdGuard Official](https://adguard.com/)
- [AdGuard Community](https://github.com/AdguardTeam/AdGuardHome/discussions)

## License

- **WireGuard** — GPL-2.0
- **WG-Easy** — Custom License (see [repository](https://github.com/wg-easy/wg-easy))
- **AdGuard Home** — GPL-3.0
