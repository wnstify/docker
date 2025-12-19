# Usage Guide

Complete guide for using your WireGuard + Pi-hole + Unbound VPN stack.

---

## Table of Contents

1. [Initial Setup](#initial-setup)
2. [Connecting VPN Clients](#connecting-vpn-clients)
3. [Pi-hole Administration](#pi-hole-administration)
4. [Recommended Blocklists 2025](#recommended-blocklists-2025)
5. [Verification & Testing](#verification--testing)
6. [Exposing Services with Pangolin](#exposing-services-with-pangolin)
7. [Maintenance](#maintenance)
8. [Advanced Configuration](#advanced-configuration)

---

## Initial Setup

### Prerequisites

- Docker and Docker Compose installed
- Public IP or domain name
- UDP port 51820 accessible from internet

### Step 1: Configure Environment

```bash
cd wg-setup
nano .env
```

**Required changes in `.env`:**

```bash
# Your public IP or domain (REQUIRED)
WG_HOST=your-public-ip-or-domain.com

# Strong, unique passwords (REQUIRED)
WG_ADMIN_PASSWORD=YourSecureVPNPassword123!
PIHOLE_PASSWORD=YourSecurePiholePassword456!

# Your timezone
TZ=Europe/Bratislava
```

### Step 2: Start Services

```bash
./setup.sh
```

Or manually:

```bash
docker compose up -d
```

### Step 3: Verify All Services Running

```bash
docker compose ps
```

Expected output:
```
NAME        STATUS                   PORTS
unbound     Up (healthy)
pihole      Up (healthy)             0.0.0.0:80->80/tcp
wireguard   Up (healthy)             0.0.0.0:51820->51820/udp, 0.0.0.0:51821->51821/tcp
```

---

## Connecting VPN Clients

### Access WireGuard Web UI

1. Open `http://YOUR_SERVER_IP:51821`
2. Login with:
   - Username: `admin`
   - Password: Your `WG_ADMIN_PASSWORD`

### Create a New Client

1. Click **"+ New"** button
2. Enter client name (e.g., "iPhone", "Laptop", "HomePC")
3. Click **"Create"**
4. Download config file or scan QR code

### Client Apps

| Platform | App | Download |
|----------|-----|----------|
| iOS | WireGuard | [App Store](https://apps.apple.com/app/wireguard/id1441195209) |
| Android | WireGuard | [Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android) |
| macOS | WireGuard | [App Store](https://apps.apple.com/app/wireguard/id1451685025) |
| Windows | WireGuard | [wireguard.com](https://www.wireguard.com/install/) |
| Linux | wg-quick | `sudo apt install wireguard` |

### Import Configuration

**Mobile (iOS/Android):**
1. Open WireGuard app
2. Tap **"+"** → **"Scan from QR Code"**
3. Scan the QR code from web UI
4. Toggle connection ON

**Desktop:**
1. Download `.conf` file from web UI
2. Import into WireGuard app
3. Activate tunnel

---

## Pi-hole Administration

### Access Pi-hole Dashboard

1. Open `http://YOUR_SERVER_IP/admin`
2. Login with your `PIHOLE_PASSWORD`

### Dashboard Overview

- **Queries Blocked Today**: Total blocked requests
- **Percent Blocked**: Block rate percentage
- **Domains on Blocklist**: Total blocked domains
- **Query Log**: Real-time DNS requests

### Adding Custom Blocklists

1. Go to **Adlists** in left menu
2. Enter blocklist URL
3. Click **Add**
4. Go to **Tools** → **Update Gravity** to apply

---

## Recommended Blocklists 2025

### Tier 1: Essential (Start Here)

These provide excellent coverage with minimal false positives:

| List | URL | Description |
|------|-----|-------------|
| **Hagezi Light** | `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/light.txt` | Minimal blocking, very few false positives |
| **OISD Basic** | `https://basic.oisd.nl/` | Curated, minimal false positives |
| **Steven Black Unified** | `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` | Classic, well-maintained |

### Tier 2: Balanced (Recommended for Most Users)

Good balance between blocking and usability:

| List | URL | Description |
|------|-----|-------------|
| **Hagezi Normal** | `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/multi.txt` | ~300K domains, excellent balance |
| **OISD Full** | `https://big.oisd.nl/` | Comprehensive, well-curated |
| **Firebog Ticked** | Multiple lists at [firebog.net](https://firebog.net/) | Community-vetted, tick = safe |

### Tier 3: Aggressive (Advanced Users)

Maximum blocking, may require whitelisting:

| List | URL | Description |
|------|-----|-------------|
| **Hagezi Pro** | `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt` | ~600K domains |
| **Hagezi Ultimate** | `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/ultimate.txt` | Maximum blocking |

### Specialty Lists

| Purpose | List | URL |
|---------|------|-----|
| **Smart TV Ads** | Perflyst | `https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt` |
| **Mobile Trackers** | Hagezi | `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/native.android.txt` |
| **Threat Intel** | Hagezi TIF | `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt` |
| **Fake News** | Hagezi | `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/fake.txt` |

### Our Recommended Setup

For most users, we recommend:

```
# Essential
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/multi.txt

# Smart TV blocking
https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt

# Threat Intelligence
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt
```

### Applying Blocklists

After adding lists:

```bash
docker exec pihole pihole -g
```

Or via web UI: **Tools** → **Update Gravity**

### Common Whitelists

If you experience issues, whitelist these domains:

```
# Microsoft
login.microsoftonline.com
graph.microsoft.com

# Apple
captive.apple.com
gsp-ssl.ls.apple.com

# Google
clients4.google.com

# General
cdn.jsdelivr.net
```

---

## Verification & Testing

### Verify DNS-over-TLS is Active

```bash
docker exec pihole dig +short TXT proto.on.quad9.net
```

Expected output: `"dot"`

### Verify DNSSEC is Working

```bash
docker exec pihole dig +short TXT dnssec.on.quad9.net
```

Expected output: `"secure"`

### Verify Malware Blocking (Quad9)

```bash
docker exec pihole dig isitblocked.org
```

Should return `NXDOMAIN` or blocked response.

### Test Ad Blocking

```bash
docker exec pihole dig ads.google.com
```

Should return `0.0.0.0` or `NXDOMAIN`.

### Check DNS Resolution Speed

```bash
docker exec pihole dig google.com | grep "Query time"
```

First query: ~50-100ms, cached queries: ~1ms.

### Full DNS Path Test

```bash
# Test from VPN client while connected
nslookup google.com
nslookup ads.google.com  # Should be blocked
```

---

## Exposing Services with Pangolin

For secure remote access to your services without exposing ports, we recommend **Pangolin** - a self-hosted alternative to Cloudflare Tunnels.

### Why Pangolin?

- **No port forwarding required** - Works behind NAT/CGNAT
- **WireGuard-based tunneling** - Same security as your VPN
- **Built-in identity management** - Control who accesses what
- **Automatic SSL** - Let's Encrypt certificates
- **Self-hosted** - Your data, your control
- **Open source** - AGPL-3 licensed

### Pangolin Architecture

```
Internet
    │
    ▼
┌─────────────────────────────┐
│    Pangolin Cloud/VPS       │
│    (Public IP with SSL)     │
└─────────────────────────────┘
    │ WireGuard Tunnel
    ▼
┌─────────────────────────────┐
│    Your Home Server         │
│    (Behind NAT/CGNAT)       │
│    ┌─────────────────────┐  │
│    │ Pi-hole Web UI      │  │
│    │ WireGuard UI        │  │
│    │ Other Services      │  │
│    └─────────────────────┘  │
└─────────────────────────────┘
```

### Installing Pangolin

**On your VPS (public-facing server):**

```bash
# Clone Pangolin
git clone https://github.com/fosrl/pangolin.git
cd pangolin

# Configure
cp .env.example .env
nano .env

# Start
docker compose up -d
```

**On your home server:**

```bash
# Install Newt (Pangolin agent)
curl -fsSL https://github.com/fosrl/newt/releases/latest/download/newt-linux-amd64 -o newt
chmod +x newt
./newt join --server https://your-pangolin-server.com
```

### Exposing Pi-hole via Pangolin

1. Access Pangolin dashboard
2. Add new site: `pihole.yourdomain.com`
3. Point to internal service: `http://localhost:80`
4. Enable SSL (automatic)
5. Set access policy (optional authentication)

### Resources

- **Website**: https://fossorial.io/
- **Documentation**: https://docs.fossorial.io/
- **Repository**: https://github.com/fosrl/pangolin
- **Discord**: Community support available

---

## Maintenance

### Daily (Automatic)

- Pi-hole updates blocklists automatically (configurable)
- Container health checks run continuously

### Weekly

```bash
# Check for container updates
docker compose pull

# View any that have updates
docker compose images

# Apply updates
docker compose up -d
```

### Monthly

```bash
# Review query logs for anomalies
docker exec pihole pihole -t  # Tail log

# Check disk usage
docker system df

# Clean unused images
docker system prune -f
```

### Backup

```bash
# Create backup
tar -czvf wg-backup-$(date +%Y%m%d).tar.gz \
  .env \
  docker-compose.yml \
  unbound/ \
  pihole/ \
  wireguard/

# Restore
tar -xzvf wg-backup-YYYYMMDD.tar.gz
docker compose up -d
```

---

## Advanced Configuration

### Split Tunneling

To route only specific traffic through VPN, modify client config:

```ini
[Interface]
# ... existing config

[Peer]
# ... existing config
AllowedIPs = 10.8.0.0/24, 10.8.1.0/24  # Only VPN traffic
# Instead of: AllowedIPs = 0.0.0.0/0  # All traffic
```

### Custom DNS Entries

Add local DNS records via Pi-hole:

1. Go to **Local DNS** → **DNS Records**
2. Add domain and IP
3. Save

Example:
```
nas.home     → 192.168.1.100
server.home  → 192.168.1.50
```

### Multiple WireGuard Clients per Device

For testing or different configurations:

1. Create multiple clients in wg-easy UI
2. Import different configs on same device
3. Only one can be active at a time

### Adjusting Cache Settings

Edit `unbound/unbound.conf`:

```yaml
server:
    # Increase cache size (default 4MB)
    msg-cache-size: 50m
    rrset-cache-size: 100m

    # Longer cache TTL
    cache-min-ttl: 300
    cache-max-ttl: 86400
```

Restart Unbound:
```bash
docker compose restart unbound
```

### Monitoring with Prometheus/Grafana

Pi-hole v6 exposes metrics at `/api/stats`:

```bash
curl http://localhost/admin/api/stats
```

For full observability, consider adding:
- Prometheus for metrics collection
- Grafana for dashboards
- Loki for log aggregation

---

## Troubleshooting

### Client Can't Connect

1. Check WireGuard is running:
   ```bash
   docker logs wireguard
   ```

2. Verify port is open:
   ```bash
   sudo ufw status | grep 51820
   ```

3. Check client config has correct endpoint

### DNS Not Resolving

1. Check Unbound:
   ```bash
   docker logs unbound
   docker exec unbound drill @127.0.0.1 -p 5335 google.com
   ```

2. Check Pi-hole:
   ```bash
   docker logs pihole
   docker exec pihole dig google.com
   ```

3. Verify upstream configuration in Pi-hole settings

### Ads Still Showing

1. Clear browser cache and DNS cache
2. Check if domain is whitelisted
3. Verify blocklists are active:
   ```bash
   docker exec pihole pihole -q ads.google.com
   ```

### Slow DNS Resolution

1. Check network latency to Quad9:
   ```bash
   docker exec unbound drill -D @9.9.9.9 -p 853 google.com
   ```

2. Increase Unbound cache size

3. Consider adding more upstream servers

---

## Support

- **Pi-hole**: https://discourse.pi-hole.net/
- **WireGuard**: https://www.wireguard.com/
- **wg-easy**: https://github.com/wg-easy/wg-easy/issues
- **Unbound**: https://nlnetlabs.nl/projects/unbound/
- **Pangolin**: https://github.com/fosrl/pangolin/discussions

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Start all services | `docker compose up -d` |
| Stop all services | `docker compose down` |
| View logs | `docker compose logs -f` |
| Update containers | `docker compose pull && docker compose up -d` |
| Update blocklists | `docker exec pihole pihole -g` |
| Check VPN status | `docker exec wireguard wg show` |
| Test DNS encryption | `docker exec pihole dig +short TXT proto.on.quad9.net` |
| Restart service | `docker compose restart SERVICE_NAME` |

---

*Last updated: December 2025*
