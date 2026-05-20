#!/usr/bin/env bash
# Reject :latest tags and untagged images in docker-compose files.
# Invoked by the pre-commit hook of the same name.
set -uo pipefail

status=0
for f in "$@"; do
  # `image: foo:latest`  or  `image: foo` (no tag at all)
  bad=$(grep -nE '^\s*image:\s*[^[:space:]]+(:latest)?\s*$' "$f" \
          | grep -E ':latest\s*$|image:\s*[^:[:space:]]+\s*$' || true)
  if [ -n "$bad" ]; then
    echo "$f: pinned-tag policy violation:"
    echo "$bad" | sed 's/^/    /'
    status=1
  fi
done
exit "$status"
