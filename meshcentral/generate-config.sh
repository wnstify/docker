#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# MeshCentral RMM — Non-interactive config generator
# Generates: .env, config.json, data directories
#
# Usage: ./generate-config.sh <domain> [--tailscale <ip>]
# ─────────────────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    echo "Usage: ./generate-config.sh <domain> [--tailscale <ip>]"
    echo "  domain              Your MeshCentral domain (e.g. rmm.example.com)"
    echo "  --tailscale <ip>    Tailscale IP of this server for agent connections"
    echo ""
    echo "Without --tailscale:"
    echo "  Agents connect via the domain through the reverse proxy."
    echo ""
    echo "With --tailscale:"
    echo "  Web UI goes through Pangolin at the domain."
    echo "  Agents connect directly via Tailscale IP (private WireGuard network)."
    echo "  Certs are generated for the Tailscale IP. WANonly mode enabled."
    exit 1
fi

DOMAIN="$1"
TAILSCALE_IP=""
shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tailscale) TAILSCALE_IP="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ── detect current user ──────────────────────────────────────────────────────
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
echo "Detected UID:GID = ${HOST_UID}:${HOST_GID}"

if [[ -n "${TAILSCALE_IP}" ]]; then
    echo "Tailscale mode: web UI via ${DOMAIN}, agents via ${TAILSCALE_IP}"
else
    echo "Standard mode: agents and web UI via ${DOMAIN} through reverse proxy"
fi

# ── helpers ──────────────────────────────────────────────────────────────────
rand_hex()  { openssl rand -hex "$1"; }

# ── guard against overwrite ──────────────────────────────────────────────────
for f in .env data/meshcentral-data/config.json; do
    if [[ -f "$f" ]]; then
        echo "ERROR: $f already exists. Remove or rename existing config before regenerating."
        exit 1
    fi
done

# ── create data directories (owned by current user) ─────────────────────────
mkdir -p data/{meshcentral-data,meshcentral-files,meshcentral-backups,mongodb}
chown -R "${HOST_UID}:${HOST_GID}" data/ 2>/dev/null || true

# ── generate secrets ─────────────────────────────────────────────────────────
DB_ENCRYPT_KEY="$(rand_hex 32)"
SESSION_KEY="$(rand_hex 32)"

# ── .env (docker compose variables) ─────────────────────────────────────────
cat > .env <<EOF
# Auto-generated — do not edit manually
PUID=${HOST_UID}
PGID=${HOST_GID}
MC_PORT=4430
TAILSCALE_IP=${TAILSCALE_IP:-127.0.0.1}
EOF
chmod 600 .env

# ── config.json (MeshCentral configuration) ─────────────────────────────────
# MongoDB has no auth — secured via internal-only Docker network (no host ports).
if [[ -n "${TAILSCALE_IP}" ]]; then
    # Tailscale mode:
    #   cert = Tailscale IP (agents connect here, certs generated for this)
    #   WANonly = true (no LAN broadcast discovery over Tailscale)
    #   No certUrl (agents go direct, not through reverse proxy)
    cat > data/meshcentral-data/config.json <<EOF
{
  "\$schema": "https://raw.githubusercontent.com/Ylianst/MeshCentral/master/meshcentral-config-schema.json",
  "settings": {
    "cert": "${TAILSCALE_IP}",
    "port": 443,
    "redirPort": 80,
    "WANonly": true,
    "mongoDb": "mongodb://mongodb:27017/meshcentral",
    "mongoDbName": "meshcentral",
    "dbEncryptKey": "${DB_ENCRYPT_KEY}",
    "sessionKey": "${SESSION_KEY}",
    "compression": true,
    "wsCompression": true,
    "agentCoreDump": false,
    "exactPorts": true,
    "allowHighQualityDesktop": true,
    "autoBackup": {
      "backupIntervalHours": 24,
      "keepLastDaysBackup": 7
    }
  },
  "domains": {
    "": {
      "title": "MeshCentral",
      "title2": "Remote Management",
      "newAccounts": true,
      "minify": true,
      "localSessionRecording": true
    }
  }
}
EOF
else
    # Standard mode:
    #   cert = domain (agents and web UI connect here)
    #   certUrl = domain (reverse proxy cert validation)
    cat > data/meshcentral-data/config.json <<EOF
{
  "\$schema": "https://raw.githubusercontent.com/Ylianst/MeshCentral/master/meshcentral-config-schema.json",
  "settings": {
    "cert": "${DOMAIN}",
    "port": 443,
    "redirPort": 80,
    "mongoDb": "mongodb://mongodb:27017/meshcentral",
    "mongoDbName": "meshcentral",
    "dbEncryptKey": "${DB_ENCRYPT_KEY}",
    "sessionKey": "${SESSION_KEY}",
    "compression": true,
    "wsCompression": true,
    "agentCoreDump": false,
    "exactPorts": true,
    "allowHighQualityDesktop": true,
    "autoBackup": {
      "backupIntervalHours": 24,
      "keepLastDaysBackup": 7
    }
  },
  "domains": {
    "": {
      "title": "MeshCentral",
      "title2": "Remote Management",
      "newAccounts": true,
      "minify": true,
      "localSessionRecording": true,
      "certUrl": "https://${DOMAIN}/"
    }
  }
}
EOF
fi

# ── done ─────────────────────────────────────────────────────────────────────
echo ""
echo "MeshCentral configuration generated for: ${DOMAIN}"
echo ""
echo "Files created:"
echo "  .env                                  — Docker Compose variables (chmod 600)"
echo "  data/meshcentral-data/config.json     — MeshCentral configuration"
echo "  data/                                 — Persistent data directories"
echo ""
echo "Next steps:"
echo "  1. Point your reverse proxy to https://127.0.0.1:4430 (TLS, skip verify)"
echo "  2. docker compose up -d"
if [[ -n "${TAILSCALE_IP}" ]]; then
    echo "  3. Visit https://${TAILSCALE_IP} or https://${DOMAIN} and create your admin account"
else
    echo "  3. Visit https://${DOMAIN} and create your admin account"
fi
echo "  4. Set \"newAccounts\": false in config.json after creating your account"
if [[ -n "${TAILSCALE_IP}" ]]; then
    echo ""
    echo "Tailscale setup:"
    echo "  - Web UI: https://${DOMAIN} (through Pangolin)"
    echo "  - Agents: connect directly via https://${TAILSCALE_IP} (Tailscale)"
    echo "  - Certs are generated for ${TAILSCALE_IP} (agents pin the cert hash)"
    echo "  - WANonly mode enabled (no LAN broadcast over Tailscale)"
    echo "  - Ensure Tailscale ACLs allow managed machines to reach this server on tcp:443"
fi
echo ""
