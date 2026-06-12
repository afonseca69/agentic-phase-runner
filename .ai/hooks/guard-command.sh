#!/usr/bin/env bash
set -euo pipefail

command_to_check="${*:-}"

if [[ -z "${command_to_check}" ]]; then
  input="$(cat || true)"
  command_to_check="${input}"
fi

blocked_patterns=(
  "migrate:fresh"
  "migrate:refresh"
  "db:wipe"
  "docker compose down -v"
  "sail down -v"
  "git push --force"
  "git clean -fdx"
  "rm -rf"
  ".env"
)

for pattern in "${blocked_patterns[@]}"; do
  if [[ "${command_to_check}" == *"${pattern}"* ]]; then
    echo "Blocked by Agentic Phase Runner guard: ${pattern}" >&2
    exit 2
  fi
done

exit 0
