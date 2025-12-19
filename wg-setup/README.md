# WireGuard + Pi-hole + Unbound Secure VPN Stack

A complete, secure VPN setup with:
- **WireGuard** - Modern, fast VPN protocol
- **Pi-hole v6** - Network-wide ad blocking
- **Unbound** - DNS resolver with Quad9 DNS-over-TLS encryption

## Features

- Full DNS encryption via Quad9 DNS-over-TLS (DoT)
- Malware blocking and DNSSEC validation (Quad9)
- Network-wide ad blocking (Pi-hole)
- Easy VPN client management via web UI (wg-easy)
- Security hardened containers
- Health checks for all services

## Architecture

```
Internet
    │
    ▼ UDP:51820
┌─────────────────────────────────────────────┐
│           WireGuard VPN Gateway             │
│           (wg-easy: 10.8.1.2)               │
└─────────────────────────────────────────────┘
    │
    ▼ DNS queries (port 53)
┌─────────────────────────────────────────────┐
│           Pi-hole v6 Ad Blocker             │
│           (10.8.1.4)                        │
└─────────────────────────────────────────────┘
    │
    ▼ DNS forwarding (port 5335)
┌─────────────────────────────────────────────┐
│           Unbound DNS Resolver              │
│           (10.8.1.3)                        │
└─────────────────────────────────────────────┘
    │
    ▼ TLS:853 (encrypted)
┌─────────────────────────────────────────────┐
│           Quad9 DNS (9.9.9.9)               │
│           Malware blocking + DNSSEC         │
└─────────────────────────────────────────────┘
```

## Quick Start

### 1. Configure Environment

```bash
# Edit the configuration
nano .env
```

**Required changes in `.env`:**

```bash
# REQUIRED: Set your public IP or domain
WG_HOST=your-server-ip-or-domain.com

# Change default passwords!
WG_ADMIN_PASSWORD=YourSecurePassword123!
PIHOLE_PASSWORD=YourSecurePassword456!
```

### 2. Run Setup

```bash
chmod +x setup.sh
./setup.sh
```

Or manually:

```bash
docker compose up -d
```

### 3. Access Web Interfaces

| Service | URL | Default User |
|---------|-----|--------------|
| WireGuard UI | `http://SERVER_IP:51821` | admin |
| Pi-hole Admin | `http://SERVER_IP:80/admin` | - |

## Configuration Files

```
wg-setup/
├── docker-compose.yml    # Main container configuration
├── .env                  # Environment configuration (edit before running)
├── setup.sh              # Automated setup script
├── README.md             # This file
├── USAGE.md              # Detailed usage guide
├── SECURITY.md           # Security best practices
├── CONTRIBUTING.md       # Credits and contribution guide
├── unbound/
│   └── unbound.conf      # Unbound DNS configuration
├── pihole/
│   └── etc-pihole/       # Pi-hole data (auto-created)
└── wireguard/            # WireGuard config (auto-created)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `Europe/Bratislava` | Timezone |
| `WG_HOST` | `vpn.example.com` | **REQUIRED**: Your public IP or domain |
| `WG_PORT` | `51820` | WireGuard VPN port (UDP) |
| `WG_UI_PORT` | `51821` | WireGuard web UI port (TCP) |
| `WG_ADMIN_USER` | `admin` | WireGuard admin username |
| `WG_ADMIN_PASSWORD` | - | **REQUIRED**: WireGuard admin password |
| `PIHOLE_PASSWORD` | - | **REQUIRED**: Pi-hole admin password |
| `PIHOLE_WEB_PORT` | `80` | Pi-hole web interface port |
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |

## Firewall Configuration

Only expose the WireGuard VPN port publicly:

```bash
# UFW (Ubuntu/Debian)
sudo ufw default deny incoming
sudo ufw allow 51820/udp comment 'WireGuard VPN'
sudo ufw allow ssh
sudo ufw enable
```

## Production Hardening

### 1. Remove INIT_* Variables After Setup

After first run, edit `docker-compose.yml` and remove:
- `INIT_ENABLED`
- `INIT_USERNAME`
- `INIT_PASSWORD`
- `INIT_HOST`
- `INIT_PORT`
- `INIT_DNS`
- `INIT_ALLOWED_IPS`

### 2. Restrict Web UI Access

For production, bind web interfaces to localhost only:

```yaml
# In docker-compose.yml
ports:
  - "127.0.0.1:80:80/tcp"      # Pi-hole (localhost only)
  - "127.0.0.1:51821:51821/tcp" # WireGuard UI (localhost only)
```

Access via SSH tunnel:
```bash
ssh -L 8080:127.0.0.1:80 -L 51821:127.0.0.1:51821 user@your-server
# Then open http://localhost:8080/admin and http://localhost:51821
```

## Verification Commands

```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f

# Verify Quad9 DoT is active
docker exec pihole dig +short TXT proto.on.quad9.net
# Expected: "dot"

# Verify DNSSEC
docker exec pihole dig +short TXT dnssec.on.quad9.net
# Expected: "secure"

# Test DNS resolution
docker exec pihole dig google.com

# Test ad blocking
docker exec pihole dig ads.google.com
# Should return 0.0.0.0 or NXDOMAIN
```

## Maintenance

### Update Containers

```bash
docker compose pull
docker compose up -d
```

### Backup

```bash
# Backup all configuration and data
tar -czvf wg-backup-$(date +%Y%m%d).tar.gz \
  .env \
  docker-compose.yml \
  unbound/ \
  pihole/ \
  wireguard/
```

### Restore

```bash
tar -xzvf wg-backup-YYYYMMDD.tar.gz
docker compose up -d
```

## Troubleshooting

### DNS not resolving

```bash
# Check Unbound logs
docker logs unbound

# Test Unbound directly
docker exec unbound drill @127.0.0.1 -p 5335 google.com
```

### Pi-hole not blocking ads

```bash
# Check Pi-hole logs
docker logs pihole

# Verify upstream DNS
docker exec pihole pihole -q google.com
```

### WireGuard clients can't connect

```bash
# Check WireGuard logs
docker logs wireguard

# Verify WireGuard is running
docker exec wireguard wg show

# Check firewall allows UDP 51820
sudo ufw status
```

### Container health check failing

```bash
# View detailed container status
docker inspect --format='{{json .State.Health}}' CONTAINER_NAME | jq

# Restart specific container
docker compose restart CONTAINER_NAME
```

## Network Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Docker Network: vpn_net                     │
│                         Subnet: 10.8.1.0/24                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │  WireGuard  │    │   Pi-hole   │    │   Unbound   │             │
│  │  10.8.1.2   │───▶│  10.8.1.4   │───▶│  10.8.1.3   │────▶ Quad9  │
│  │  :51820/udp │    │  :53        │    │  :5335      │     (DoT)   │
│  │  :51821/tcp │    │  :80        │    │             │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
│        ▲                                                            │
│        │                                                            │
└────────┼────────────────────────────────────────────────────────────┘
         │
    VPN Clients
    (10.8.0.x)
```

## License

This configuration is provided as-is for personal use.

## Credits

- [Pi-hole](https://pi-hole.net/)
- [WireGuard](https://www.wireguard.com/)
- [wg-easy](https://github.com/wg-easy/wg-easy)
- [Unbound](https://nlnetlabs.nl/projects/unbound/)
- [Quad9](https://quad9.net/)
