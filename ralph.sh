#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
AI_DIR="${ROOT_DIR}/.ai"
RUNS_DIR="${AI_DIR}/runs"
BLUEPRINT="${AI_DIR}/project-blueprint.yaml"
PHASES_DOC="${ROOT_DIR}/docs/project-phases.md"

COMMAND="${1:-help}"
shift || true

MANAGER="${APR_MANAGER:-hermes}"
EXECUTOR="${APR_EXECUTOR:-dry-run}"
REVIEWER="${APR_REVIEWER:-none}"
UNTIL="next-gate"
PHASE=""
DRY_RUN="false"

usage() {
  cat <<'EOF'
Agentic Phase Runner

Usage:
  ./ralph.sh init
  ./ralph