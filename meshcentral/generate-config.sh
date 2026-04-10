#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# MeshCentral RMM — Non-interactive config generator
# Generates: .env, config.json, data directories
#
# Usage: ./generate-config.sh <domain>
# ─────────────────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    echo "Usage: ./generate-config.sh <domain>"
    echo "  domain    Your MeshCentral domain (e.g. rmm.example.com)"
    exit 1
fi

DOMAIN="$1"

# ── detect current user ──────────────────────────────────────────────────────
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
echo "Detected UID:GID = ${HOST_UID}:${HOST_GID}"

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
EOF
chmod 600 .env

# ── config.json (MeshCentral configuration) ─────────────────────────────────
# Agents connect on port 443 (same as web UI) via reverse proxy.
# MongoDB has no auth — secured via internal-only Docker network (no host ports).
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
echo "  3. Visit https://${DOMAIN} and create your admin account"
echo "  4. Set \"newAccounts\": false in config.json after creating your account"
echo ""
