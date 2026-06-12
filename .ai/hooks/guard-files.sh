#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${APR_ROOT_DIR:-$(pwd)}"
PATTERNS_FILE="${APR_PROTECTED_PATHS:-$ROOT_DIR/.ai/guardrails/protected-paths.txt}"

if [[ ! -f "$PATTERNS_FILE" ]]; then
  echo "guard-files: no protected path list found at $PATTERNS_FILE"
  exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "guard-files: not inside a git repository"
  exit 0
fi

changed_files="$(git status --porcelain | awk '{print $2}' || true)"
if [[ -z "$changed_files" ]]; then
  echo "guard-files: no changed files"
  exit 0
fi

blocked=0
while IFS= read -r pattern; do
  [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if [[ "$file" == $pattern ]]; then
      echo "guard-files: protected path changed: $file matches $pattern" >&2
      blocked=1
    fi
  done <<< "$changed_files"
done < "$PATTERNS_FILE"

if [[ "$blocked" == "1" ]]; then
  echo "guard-files: review required before continuing" >&2
  exit 2
fi

echo "guard-files: ok"
