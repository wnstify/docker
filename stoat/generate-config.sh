#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Stoat (formerly Revolt) — Non-interactive config generator
# Generates: .env, secrets.env, .env.web, Revolt.toml, garage.toml, livekit.yml
# Creates:   data/ subdirectories
#
# Usage: ./generate-config.sh <domain> [--enable-video]
# ─────────────────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    echo "Usage: ./generate-config.sh <domain> [--enable-video]"
    echo "  domain         Your Stoat domain (e.g. chat.example.com)"
    echo "  --enable-video Enable camera and screen sharing"
    exit 1
fi

DOMAIN="$1"
VIDEO_ENABLED=""
if [[ "${2:-}" == "--enable-video" ]]; then
    VIDEO_ENABLED="true"
fi

# ── helpers ──────────────────────────────────────────────────────────────────
rand_hex()  { openssl rand -hex "$1"; }
rand_b64()  { openssl rand -base64 "$1"; }

# ── guard against overwrite ──────────────────────────────────────────────────
for f in .env secrets.env .env.web Revolt.toml garage.toml livekit.yml; do
    if [[ -f "$f" ]]; then
        echo "ERROR: $f already exists. Remove or rename existing config before regenerating."
        exit 1
    fi
done

# ── create data directories (owned by 1000:1000 for non-root containers) ────
mkdir -p data/{db,redis,rabbit,garage-meta,garage-data}
chown -R 1000:1000 data/ 2>/dev/null || true

# ── generate infrastructure credentials ──────────────────────────────────────
MONGO_ROOT_USER="stoat"
MONGO_ROOT_PASSWORD="$(rand_hex 24)"
REDIS_PASSWORD="$(rand_hex 24)"
RABBIT_USER="stoatrabbit"
RABBIT_PASSWORD="$(rand_hex 24)"

# Garage S3 credentials
GARAGE_RPC_SECRET="$(rand_hex 32)"
GARAGE_ADMIN_TOKEN="$(rand_b64 32)"
GARAGE_METRICS_TOKEN="$(rand_b64 32)"
S3_ACCESS_KEY="GK$(rand_hex 12)"
S3_SECRET_KEY="$(rand_hex 32)"

# ── generate application secrets ─────────────────────────────────────────────
FILES_ENCRYPTION_KEY="$(rand_b64 32)"
LIVEKIT_KEY="$(rand_hex 6)"
LIVEKIT_SECRET="$(rand_hex 24)"

# VAPID keys for push notifications
openssl ecparam -name prime256v1 -genkey -noout -out /tmp/vapid_private.pem 2>/dev/null
VAPID_PRIVATE="$(base64 -w0 /tmp/vapid_private.pem | tr -d '=')"
VAPID_PUBLIC="$(openssl ec -in /tmp/vapid_private.pem -outform DER 2>/dev/null \
    | tail -c 65 | base64 -w0 | tr '/+' '_-' | tr -d '=')"
rm -f /tmp/vapid_private.pem

# ── .env (docker compose variable substitution) ─────────────────────────────
cat > .env <<EOF
# Auto-generated — do not edit manually
# Infrastructure credentials for docker compose services
STOAT_DOMAIN=${DOMAIN}
MONGO_ROOT_USER=${MONGO_ROOT_USER}
MONGO_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
RABBIT_USER=${RABBIT_USER}
RABBIT_PASSWORD=${RABBIT_PASSWORD}
GARAGE_ADMIN_TOKEN=${GARAGE_ADMIN_TOKEN}
S3_ACCESS_KEY=${S3_ACCESS_KEY}
S3_SECRET_KEY=${S3_SECRET_KEY}
EOF
chmod 600 .env

# ── secrets.env (Stoat service env overrides) ────────────────────────────────
cat > secrets.env <<EOF
# Auto-generated — do not edit manually
# Stoat application secrets (REVOLT__ prefix maps to Revolt.toml sections)

# Database connections (with auth)
REVOLT__DATABASE__MONGODB=mongodb://${MONGO_ROOT_USER}:${MONGO_ROOT_PASSWORD}@database:27017/revolt?authSource=admin
REVOLT__DATABASE__REDIS=redis://:${REDIS_PASSWORD}@redis:6379/

# RabbitMQ
REVOLT__RABBIT__HOST=rabbit
REVOLT__RABBIT__PORT=5672
REVOLT__RABBIT__USERNAME=${RABBIT_USER}
REVOLT__RABBIT__PASSWORD=${RABBIT_PASSWORD}

# Garage S3 file storage
REVOLT__FILES__S3__ENDPOINT=http://garage:3900
REVOLT__FILES__S3__ACCESS_KEY_ID=${S3_ACCESS_KEY}
REVOLT__FILES__S3__SECRET_ACCESS_KEY=${S3_SECRET_KEY}
REVOLT__FILES__S3__DEFAULT_BUCKET=revolt-uploads
REVOLT__FILES__S3__REGION=garage
REVOLT__FILES__S3__PATH_STYLE_BUCKETS=true
REVOLT__FILES__ENCRYPTION_KEY=${FILES_ENCRYPTION_KEY}

# Push notification VAPID keys
REVOLT__PUSHD__VAPID__PRIVATE_KEY=${VAPID_PRIVATE}
REVOLT__PUSHD__VAPID__PUBLIC_KEY=${VAPID_PUBLIC}

# LiveKit voice
REVOLT__API__LIVEKIT__NODES__WORLDWIDE__KEY=${LIVEKIT_KEY}
REVOLT__API__LIVEKIT__NODES__WORLDWIDE__SECRET=${LIVEKIT_SECRET}
EOF
chmod 600 secrets.env

# ── .env.web (frontend + caddy) ─────────────────────────────────────────────
# HOSTNAME=:80 because Pangolin handles TLS externally
cat > .env.web <<EOF
HOSTNAME=:80
REVOLT_PUBLIC_URL=https://${DOMAIN}/api
VITE_API_URL=https://${DOMAIN}/api
VITE_WS_URL=wss://${DOMAIN}/ws
VITE_MEDIA_URL=https://${DOMAIN}/autumn
VITE_PROXY_URL=https://${DOMAIN}/january
VITE_CFG_ENABLE_VIDEO=${VIDEO_ENABLED}
VITE_GIFBOX_URL=https://${DOMAIN}/gifbox
EOF

# ── garage.toml (Garage S3 storage config) ───────────────────────────────────
cat > garage.toml <<EOF
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "sqlite"
replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "garage:3901"
rpc_secret = "${GARAGE_RPC_SECRET}"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage"
index = "index.html"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "${GARAGE_ADMIN_TOKEN}"
metrics_token = "${GARAGE_METRICS_TOKEN}"
EOF

# ── Revolt.toml (non-sensitive config) ───────────────────────────────────────
cat > Revolt.toml <<'TOML_HEADER'
# All secrets are in secrets.env (env vars override these values)
# Edit hosts and feature limits here; regenerate secrets with generate-config.sh
TOML_HEADER

cat >> Revolt.toml <<EOF

[hosts]
app = "https://${DOMAIN}"
api = "https://${DOMAIN}/api"
events = "wss://${DOMAIN}/ws"
autumn = "https://${DOMAIN}/autumn"
january = "https://${DOMAIN}/january"

[hosts.livekit]
worldwide = "wss://${DOMAIN}/livekit"

[api.livekit.nodes.worldwide]
url = "http://livekit:7880"
lat = 0.0
lon = 0.0

[api.registration]
invite_only = false

[features]
webhooks_enabled = false
EOF

if [[ -n "$VIDEO_ENABLED" ]]; then
    cat >> Revolt.toml <<EOF

[features.limits.new_user]
video = true
video_resolution = [1920, 1080]
video_aspect_ratio = [0.3, 10]

[features.limits.default]
video = true
video_resolution = [1920, 1080]
video_aspect_ratio = [0.3, 10]
EOF
fi

# ── livekit.yml ──────────────────────────────────────────────────────────────
cat > livekit.yml <<EOF
rtc:
  use_external_ip: true
  port_range_start: 50000
  port_range_end: 50100
  tcp_port: 7881

redis:
  address: redis:6379
  password: "${REDIS_PASSWORD}"

turn:
  enabled: false

keys:
  ${LIVEKIT_KEY}: ${LIVEKIT_SECRET}

webhook:
  api_key: ${LIVEKIT_KEY}
  urls:
  - "http://voice-ingress:8500/worldwide"
EOF

# ── done ─────────────────────────────────────────────────────────────────────
echo ""
echo "Stoat configuration generated for: ${DOMAIN}"
echo ""
echo "Files created:"
echo "  .env          — Infrastructure credentials (chmod 600)"
echo "  secrets.env   — Application secrets (chmod 600)"
echo "  .env.web      — Frontend environment"
echo "  Revolt.toml   — Stoat configuration"
echo "  garage.toml   — Garage S3 storage config"
echo "  livekit.yml   — LiveKit voice server config"
echo "  data/         — Persistent data directories"
echo ""
echo "Next steps:"
echo "  1. Review Revolt.toml (set invite_only = true if needed)"
echo "  2. Point your reverse proxy to 127.0.0.1:8880"
echo "  3. Open UDP ports 50000-50100 and TCP 7881 in your firewall for voice"
echo "  4. docker compose up -d"
echo ""
