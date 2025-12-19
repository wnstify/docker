#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# WireGuard + Pi-hole + Unbound Setup Script
# Secure VPN with Ad-blocking and Encrypted DNS (Quad9 DoT)
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Header
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  WireGuard + Pi-hole + Unbound Secure VPN Setup${NC}"
echo -e "${BLUE}  DNS Encryption: Quad9 DNS-over-TLS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running from correct directory
if [ ! -f "docker-compose.yml" ]; then
    error "docker-compose.yml not found. Please run this script from the wg-setup directory."
fi

# Check prerequisites
info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

if ! docker compose version &> /dev/null; then
    error "Docker Compose is not available. Please install Docker Compose."
fi

success "Docker and Docker Compose are installed."

# Check .env file
if [ ! -f ".env" ]; then
    error ".env file not found. Please ensure .env exists with your configuration."
fi

# Validate .env configuration
source .env

if [ "$WG_HOST" == "vpn.example.com" ] || [ "$WG_HOST" == "your-server-ip-or-domain.com" ] || [ -z "$WG_HOST" ]; then
    warn "WG_HOST is not configured properly in .env file!"
    echo ""
    read -p "Enter your public IP or domain name: " WG_HOST_INPUT
    if [ -z "$WG_HOST_INPUT" ]; then
        error "WG_HOST cannot be empty."
    fi
    sed -i.bak "s|WG_HOST=.*|WG_HOST=$WG_HOST_INPUT|" .env
    success "Updated WG_HOST to: $WG_HOST_INPUT"
fi

if [ "$WG_ADMIN_PASSWORD" == "ChangeThisPassword123!" ] || [ "$WG_ADMIN_PASSWORD" == "CHANGE_ME_USE_STRONG_PASSWORD" ]; then
    warn "WG_ADMIN_PASSWORD is using default value!"
    read -p "Enter a new WireGuard admin password: " WG_PASS_INPUT
    if [ -z "$WG_PASS_INPUT" ]; then
        error "Password cannot be empty."
    fi
    sed -i.bak "s|WG_ADMIN_PASSWORD=.*|WG_ADMIN_PASSWORD=$WG_PASS_INPUT|" .env
    success "Updated WireGuard admin password."
fi

if [ "$PIHOLE_PASSWORD" == "ChangeThisPassword456!" ] || [ "$PIHOLE_PASSWORD" == "CHANGE_ME_USE_STRONG_PASSWORD" ]; then
    warn "PIHOLE_PASSWORD is using default value!"
    read -p "Enter a new Pi-hole admin password: " PIHOLE_PASS_INPUT
    if [ -z "$PIHOLE_PASS_INPUT" ]; then
        error "Password cannot be empty."
    fi
    sed -i.bak "s|PIHOLE_PASSWORD=.*|PIHOLE_PASSWORD=$PIHOLE_PASS_INPUT|" .env
    success "Updated Pi-hole admin password."
fi

# Clean up backup files
rm -f .env.bak

# Create required directories
info "Creating directory structure..."
mkdir -p unbound pihole/etc-pihole wireguard
success "Directories created."

# Set permissions
info "Setting file permissions..."
chmod 600 .env
chmod 644 unbound/unbound.conf
success "Permissions set."

# Validate docker-compose
info "Validating docker-compose configuration..."
if docker compose config > /dev/null 2>&1; then
    success "Docker Compose configuration is valid."
else
    error "Docker Compose configuration is invalid. Please check docker-compose.yml"
fi

# Pull images
info "Pulling Docker images (this may take a few minutes)..."
docker compose pull
success "Docker images pulled."

# Start containers
info "Starting containers..."
docker compose up -d
success "Containers started."

# Wait for services
info "Waiting for services to become healthy..."
echo ""

# Wait for Unbound
echo -n "  Unbound: "
for i in {1..30}; do
    if docker inspect --format='{{.State.Health.Status}}' unbound 2>/dev/null | grep -q "healthy"; then
        echo -e "${GREEN}healthy${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for Pi-hole
echo -n "  Pi-hole: "
for i in {1..60}; do
    if docker inspect --format='{{.State.Health.Status}}' pihole 2>/dev/null | grep -q "healthy"; then
        echo -e "${GREEN}healthy${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for WireGuard
echo -n "  WireGuard: "
for i in {1..30}; do
    if docker inspect --format='{{.State.Health.Status}}' wireguard 2>/dev/null | grep -q "healthy"; then
        echo -e "${GREEN}healthy${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""

# Verify DNS is working
info "Testing DNS resolution..."
if docker exec unbound drill @127.0.0.1 -p 5335 quad9.net > /dev/null 2>&1; then
    success "Unbound DNS is working."
else
    warn "Unbound DNS test failed. Please check logs with: docker logs unbound"
fi

# Verify Quad9 DoT
info "Verifying Quad9 DNS-over-TLS..."
DOT_TEST=$(docker exec pihole dig +short TXT proto.on.quad9.net 2>/dev/null | tr -d '"')
if [ "$DOT_TEST" == "dot" ]; then
    success "Quad9 DNS-over-TLS is active!"
else
    warn "Could not verify DoT. Response: $DOT_TEST"
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "YOUR_SERVER_IP")

# Reload .env for final values
source .env

# Print summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BLUE}WireGuard VPN:${NC}"
echo -e "    Web UI:     http://${SERVER_IP}:${WG_UI_PORT:-51821}"
echo -e "    VPN Port:   ${WG_PORT:-51820}/UDP"
echo -e "    Username:   ${WG_ADMIN_USER:-admin}"
echo ""
echo -e "  ${BLUE}Pi-hole:${NC}"
echo -e "    Admin:      http://${SERVER_IP}:${PIHOLE_WEB_PORT:-80}/admin"
echo ""
echo -e "  ${BLUE}DNS:${NC}"
echo -e "    Upstream:   Quad9 (9.9.9.9) via DNS-over-TLS"
echo -e "    Features:   Malware blocking, DNSSEC validation"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  IMPORTANT: Security Recommendations${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  1. Configure your firewall to only allow port ${WG_PORT:-51820}/UDP publicly"
echo -e "  2. After first setup, remove INIT_* variables from docker-compose.yml"
echo -e "  3. Use SSH tunnel for web UI access in production:"
echo -e "     ssh -L 8080:127.0.0.1:80 -L 51821:127.0.0.1:51821 user@server"
echo ""
echo -e "  ${BLUE}Useful Commands:${NC}"
echo -e "    View logs:      docker compose logs -f"
echo -e "    Restart:        docker compose restart"
echo -e "    Stop:           docker compose down"
echo -e "    Update:         docker compose pull && docker compose up -d"
echo ""
