#!/usr/bin/env bash
set -euo pipefail

runs_dir="${APR_RUNS_DIR:-.ai/runs}"
mkdir -p "${runs_dir}"

event="${1:-event}"
detail="${2:-}"

printf '{"ts":"%s","event":"%s","detail":"%s"}\n' "$(date -Is)" "${event}" "${detail}" >> "${runs_dir}/events.jsonl"
