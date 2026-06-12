#!/usr/bin/env bash
set -euo pipefail

runs_dir="${APR_RUNS_DIR:-.ai/runs}"
mkdir -p "${runs_dir}"

model="${1:-unknown}"
input_tokens="${2:-0}"
output_tokens="${3:-0}"
cost="${4:-0}"

printf '{"ts":"%s","model":"%s","input_tokens":%s,"output_tokens":%s,"cost":%s}\n' \
  "$(date -Is)" "${model}" "${input_tokens}" "${output_tokens}" "${cost}" >> "${runs_dir}/tokens.jsonl"
