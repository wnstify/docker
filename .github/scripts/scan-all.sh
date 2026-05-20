#!/usr/bin/env bash
# Scan every image referenced in every docker-compose.yml in the repo.
# Writes one JSON per unique image into $OUT_DIR. Used by weekly-audit.yml.
set -uo pipefail

OUT_DIR="${1:-.audit/scans}"
TRIVY="${TRIVY:-trivy}"

mkdir -p "$OUT_DIR"

# Unique image refs across every compose file
mapfile -t images < <(
  grep -rhE '^\s*image:\s*' --include='docker-compose.yml' --include='docker-compose.yaml' . \
    | sed -E 's/^\s*image:\s*//; s/[[:space:]]+#.*$//; s/[[:space:]]+$//' \
    | sort -u
)

if [ "${#images[@]}" -eq 0 ]; then
  echo "No images found." >&2
  exit 1
fi

echo "Scanning ${#images[@]} images into $OUT_DIR"

# Slug helper: turn an image ref into a filesystem-safe filename
slug() {
  echo "$1" | sed 's|[/:]|-|g; s|@.*||'
}

fails=()
for img in "${images[@]}"; do
  out="$OUT_DIR/$(slug "$img").json"
  echo "=== $img"
  if ! "$TRIVY" image \
        --severity CRITICAL,HIGH,MEDIUM,LOW \
        --no-progress \
        --skip-db-update \
        --scanners vuln \
        --format json \
        --quiet \
        --timeout 15m \
        -o "$out" \
        "$img"; then
    fails+=("$img")
    echo "FAILED: $img" >&2
  fi
done

# Persist the image inventory so downstream scripts know what was meant to scan
printf '%s\n' "${images[@]}" > "$OUT_DIR/_inventory.txt"

if [ "${#fails[@]}" -gt 0 ]; then
  printf '%s\n' "${fails[@]}" > "$OUT_DIR/_failures.txt"
  echo "::warning::Trivy scan failed for ${#fails[@]} image(s); see _failures.txt"
fi

echo "Done. ${#images[@]} attempted, ${#fails[@]} failed."
