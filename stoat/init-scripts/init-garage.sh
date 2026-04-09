#!/bin/sh
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Garage S3 bootstrap: layout assignment, bucket creation, API key import
# Runs once as an init container; exits 0 on success.
# ─────────────────────────────────────────────────────────────────────────────

apk add --no-cache curl jq >/dev/null 2>&1

ADMIN="http://garage:3903"
AUTH="Authorization: Bearer ${GARAGE_ADMIN_TOKEN}"

# ── wait for admin API ───────────────────────────────────────────────────────
echo "[garage-init] Waiting for Garage admin API..."
attempts=0
while ! curl -sf -H "${AUTH}" "${ADMIN}/v2/GetClusterStatus" >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "${attempts}" -ge 30 ]; then
        echo "[garage-init] ERROR: Garage admin API not reachable after 60s"
        exit 1
    fi
    sleep 2
done
echo "[garage-init] Garage admin API is up"

# ── check if layout is already applied ───────────────────────────────────────
LAYOUT_VERSION=$(curl -sf -H "${AUTH}" "${ADMIN}/v2/GetClusterLayout" | jq -r '.version')
if [ "${LAYOUT_VERSION}" -gt 0 ] 2>/dev/null; then
    echo "[garage-init] Layout already applied (version ${LAYOUT_VERSION}), skipping layout setup"
else
    # ── assign layout (single-node, 10 GB capacity) ─────────────────────────
    echo "[garage-init] Configuring cluster layout..."
    NODE_ID=$(curl -sf -H "${AUTH}" "${ADMIN}/v2/GetClusterStatus" \
        | jq -r '.nodes[] | select(.isUp == true) | .id' | head -1)

    if [ -z "${NODE_ID}" ]; then
        echo "[garage-init] ERROR: Could not find an active Garage node"
        exit 1
    fi
    echo "[garage-init] Node ID: ${NODE_ID}"

    # v2 API: {"roles": [{...}]} wrapper format
    cat > /tmp/layout.json <<EOF
{"roles":[{"id":"${NODE_ID}","zone":"dc1","capacity":10737418240,"tags":[]}]}
EOF

    curl -sf -X POST -H "${AUTH}" -H "Content-Type: application/json" \
        -d @/tmp/layout.json "${ADMIN}/v2/UpdateClusterLayout" >/dev/null

    CURRENT_VERSION=$(curl -sf -H "${AUTH}" "${ADMIN}/v2/GetClusterLayout" | jq -r '.version')
    NEXT_VERSION=$((CURRENT_VERSION + 1))

    echo "{\"version\":${NEXT_VERSION}}" > /tmp/apply.json
    curl -sf -X POST -H "${AUTH}" -H "Content-Type: application/json" \
        -d @/tmp/apply.json "${ADMIN}/v2/ApplyClusterLayout" >/dev/null

    FINAL_VERSION=$(curl -sf -H "${AUTH}" "${ADMIN}/v2/GetClusterLayout" | jq -r '.version')
    echo "[garage-init] Layout applied (version ${FINAL_VERSION})"
fi

# ── import S3 key ────────────────────────────────────────────────────────────
echo "[garage-init] Importing S3 access key..."
cat > /tmp/key.json <<EOF
{"accessKeyId":"${S3_ACCESS_KEY}","secretAccessKey":"${S3_SECRET_KEY}","name":"stoat"}
EOF

KEY_RESP=$(curl -sf -X POST -H "${AUTH}" -H "Content-Type: application/json" \
    -d @/tmp/key.json "${ADMIN}/v2/ImportKey" 2>/dev/null || true)
if [ -n "${KEY_RESP}" ]; then
    echo "[garage-init] Key imported"
else
    echo "[garage-init] Key already exists or import skipped"
fi

# ── create bucket ────────────────────────────────────────────────────────────
echo "[garage-init] Creating revolt-uploads bucket..."
BUCKET_RESP=$(curl -sf -X POST -H "${AUTH}" -H "Content-Type: application/json" \
    -d '{"globalAlias":"revolt-uploads"}' "${ADMIN}/v2/CreateBucket" 2>/dev/null || true)

if [ -n "${BUCKET_RESP}" ]; then
    BUCKET_ID=$(echo "${BUCKET_RESP}" | jq -r '.id')
    echo "[garage-init] Bucket created: ${BUCKET_ID}"
else
    BUCKET_ID=$(curl -sf -H "${AUTH}" "${ADMIN}/v2/ListBuckets" \
        | jq -r '.[] | select(.globalAliases != null) | select(.globalAliases[] == "revolt-uploads") | .id')
    echo "[garage-init] Bucket already exists: ${BUCKET_ID}"
fi

if [ -z "${BUCKET_ID}" ] || [ "${BUCKET_ID}" = "null" ]; then
    echo "[garage-init] ERROR: Could not create or find revolt-uploads bucket"
    exit 1
fi

# ── grant key access ─────────────────────────────────────────────────────────
echo "[garage-init] Granting key access to bucket..."
cat > /tmp/allow.json <<EOF
{"bucketId":"${BUCKET_ID}","accessKeyId":"${S3_ACCESS_KEY}","permissions":{"read":true,"write":true,"owner":true}}
EOF

curl -sf -X POST -H "${AUTH}" -H "Content-Type: application/json" \
    -d @/tmp/allow.json "${ADMIN}/v2/AllowBucketKey" >/dev/null 2>&1 || echo "[garage-init] Key already has access"

rm -f /tmp/layout.json /tmp/apply.json /tmp/key.json /tmp/allow.json

echo "[garage-init] Initialization complete"
