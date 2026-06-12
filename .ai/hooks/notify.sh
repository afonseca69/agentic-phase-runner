#!/usr/bin/env bash
set -euo pipefail

message="${*:-Agentic Phase Runner notification}"

if [[ -n "${APR_NOTIFY_WEBHOOK:-}" ]]; then
  curl -fsS -X POST "${APR_NOTIFY_WEBHOOK}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\":\"${message}\"}" >/dev/null
else
  echo "Notification: ${message}"
fi
