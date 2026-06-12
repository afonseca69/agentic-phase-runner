#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${APR_ROOT_DIR:-$(pwd)}"
PHASE="${1:-}"
RUNS_DIR="$ROOT_DIR/.ai/runs"

if [[ -z "$PHASE" ]]; then
  echo "usage: check-phase-close.sh PHASE_ID" >&2
  exit 64
fi

mkdir -p "$RUNS_DIR/summaries" "$RUNS_DIR/reviews"

missing=0

if [[ ! -f "$RUNS_DIR/summaries/$PHASE.md" ]]; then
  echo "check-phase-close: missing summary: .ai/runs/summaries/$PHASE.md" >&2
  missing=1
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if ! git diff --check --quiet; then
    echo "check-phase-close: git diff --check reported issues" >&2
    missing=1
  fi
fi

if [[ "$missing" == "1" ]]; then
  echo "check-phase-close: phase is not ready to close" >&2
  exit 2
fi

echo "check-phase-close: ok"
