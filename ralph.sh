#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
AI_DIR="${ROOT_DIR}/.ai"
RUNS_DIR="${AI_DIR}/runs"
BLUEPRINT="${AI_DIR}/project-blueprint.yaml"
PHASES_DOC="${ROOT_DIR}/docs/project-phases.md"

COMMAND="${1:-help}"
if [[ $# -gt 0 ]]; then
  shift
fi

MANAGER="${APR_MANAGER:-hermes}"
EXECUTOR="${APR_EXECUTOR:-dry-run}"
REVIEWER="${APR_REVIEWER:-none}"
PHASE=""
UNTIL="next-gate"
DRY_RUN="false"

usage() {
  cat <<'EOF'
Agentic Phase Runner

Usage:
  ./ralph.sh init
  ./ralph.sh plan
  ./ralph.sh status
  ./ralph.sh run [--phase F01] [--executor dry-run|codex|minimax|claude|custom] [--reviewer none|codex|minimax|claude|custom] [--manager hermes|none] [--dry-run]
  ./ralph.sh close-phase --phase F01

Environment overrides:
  APR_MANAGER=hermes
  APR_EXECUTOR=dry-run
  APR_REVIEWER=none
  APR_CUSTOM_EXECUTOR_CMD="your command"
  APR_CUSTOM_REVIEWER_CMD="your command"

This public template is intentionally safe by default. The default executor is dry-run.
EOF
}

log_event() {
  mkdir -p "${RUNS_DIR}"
  local event="$1"
  local detail="${2:-}"
  printf '{"ts":"%s","event":"%s","detail":"%s"}\n' "$(date -Is)" "$event" "$detail" >> "${RUNS_DIR}/events.jsonl"
}

ensure_dirs() {
  mkdir -p \
    "${AI_DIR}/prompts" \
    "${AI_DIR}/hooks" \
    "${RUNS_DIR}/logs" \
    "${RUNS_DIR}/prompts" \
    "${RUNS_DIR}/reviews" \
    "${RUNS_DIR}/summaries" \
    "${ROOT_DIR}/docs/decisions"
}

init_project() {
  ensure_dirs

  if [[ ! -f "${BLUEPRINT}" ]]; then
    cp "${ROOT_DIR}/.ai/templates/project-blueprint.yaml" "${BLUEPRINT}" 2>/dev/null || true
  fi

  if [[ ! -f "${PHASES_DOC}" ]]; then
    cat > "${PHASES_DOC}" <<'EOF'
# Project Phases

## F01 — Discovery

Goal: define the initial scope, constraints, risks, and acceptance criteria.

Acceptance:
- Project description exists.
- Initial architecture notes exist.
- Safety gates are reviewed.

## F02 — First implementation slice

Goal: implement a small, testable vertical slice.

Acceptance:
- A small feature or artifact is created.
- Validation commands are documented.
- Summary is written.
EOF
  fi

  touch "${RUNS_DIR}/events.jsonl" "${RUNS_DIR}/tokens.jsonl" "${RUNS_DIR}/phases.jsonl"
  log_event "init" "project initialized"
  echo "Initialized Agentic Phase Runner structure."
}

extract_phase_from_docs() {
  local requested="$1"
  if [[ ! -f "${PHASES_DOC}" ]]; then
    echo "docs/project-phases.md not found. Run ./ralph.sh init first." >&2
    exit 1
  fi

  if [[ -n "${requested}" ]]; then
    awk -v phase="${requested}" '
      $0 ~ "^## " phase " " {found=1}
      found && /^## F[0-9][0-9]/ && $0 !~ "^## " phase " " {exit}
      found {print}
    ' "${PHASES_DOC}"
  else
    awk '
      /^## F[0-9][0-9]/ {if (found) exit; found=1}
      found {print}
    ' "${PHASES_DOC}"
  fi
}

generate_prompt() {
  local phase_id="$1"
  local phase_content="$2"
  local prompt_file="${RUNS_DIR}/prompts/${phase_id:-next}-executor.md"

  cat > "${prompt_file}" <<EOF
You are the executor for a single controlled project phase.

Phase:
${phase_content}

Rules:
- Execute only this phase.
- Do not expand scope.
- Do not read or print secrets, tokens, API keys, or .env files.
- Do not run destructive commands.
- Do not deploy.
- Do not call real external APIs unless the blueprint explicitly allows it.
- Prefer small, testable changes.
- Report files changed, commands run, tests run, risks, and pending work.

EOF

  echo "${prompt_file}"
}

run_manager() {
  local phase_id="$1"
  local phase_content="$2"

  log_event "manager" "${MANAGER} validating ${phase_id:-next}"
  if [[ "${MANAGER}" == "none" ]]; then
    return 0
  fi

  cat > "${RUNS_DIR}/prompts/${phase_id:-next}-manager.md" <<EOF
You are the project governor.

Read the phase below and decide whether it is safe to execute.

Phase:
${phase_content}

Return:
- allowed_to_run: true/false
- executor recommendation
- reviewer recommendation
- safety gates
- acceptance criteria

Do not implement anything.

EOF

  echo "Manager prompt written to ${RUNS_DIR}/prompts/${phase_id:-next}-manager.md"
}

run_executor() {
  local prompt_file="$1"
  log_event "executor" "${EXECUTOR} using ${prompt_file}"

  case "${EXECUTOR}" in
    dry-run)
      echo "Dry run executor. Prompt written to: ${prompt_file}"
      ;;
    codex)
      codex exec "$(cat "${prompt_file}")" | tee "${RUNS_DIR}/logs/executor-codex.log"
      ;;
    claude)
      claude -p "$(cat "${prompt_file}")" | tee "${RUNS_DIR}/logs/executor-claude.log"
      ;;
    minimax)
      echo "MiniMax executor is adapter-based. Set APR_CUSTOM_EXECUTOR_CMD to integrate your CLI/API wrapper." >&2
      exit 2
      ;;
    custom)
      if [[ -z "${APR_CUSTOM_EXECUTOR_CMD:-}" ]]; then
        echo "APR_CUSTOM_EXECUTOR_CMD is required for custom executor." >&2
        exit 2
      fi
      bash -lc "${APR_CUSTOM_EXECUTOR_CMD} '${prompt_file}'" | tee "${RUNS_DIR}/logs/executor-custom.log"
      ;;
    *)
      echo "Unknown executor: ${EXECUTOR}" >&2
      exit 2
      ;;
  esac
}

run_reviewer() {
  local phase_id="$1"
  if [[ "${REVIEWER}" == "none" ]]; then
    return 0
  fi

  local review_prompt="${RUNS_DIR}/prompts/${phase_id:-next}-reviewer.md"
  cat > "${review_prompt}" <<EOF
You are the reviewer for this phase.

Review the current repository diff and execution summary.

Check:
- scope respected
- safety rules respected
- tests/validation are sufficient
- documentation was updated when needed
- risks or required fixes

Return approved: true/false with issues and required fixes.

EOF

  log_event "reviewer" "${REVIEWER} reviewing ${phase_id:-next}"

  case "${REVIEWER}" in
    codex)
      codex exec "$(cat "${review_prompt}")" | tee "${RUNS_DIR}/reviews/${phase_id:-next}-codex.md"
      ;;
    claude)
      claude -p "$(cat "${review_prompt}")" | tee "${RUNS_DIR}/reviews/${phase_id:-next}-claude.md"
      ;;
    minimax|custom)
      if [[ -z "${APR_CUSTOM_REVIEWER_CMD:-}" ]]; then
        echo "APR_CUSTOM_REVIEWER_CMD is required for ${REVIEWER} reviewer." >&2
        exit 2
      fi
      bash -lc "${APR_CUSTOM_REVIEWER_CMD} '${review_prompt}'" | tee "${RUNS_DIR}/reviews/${phase_id:-next}-custom.md"
      ;;
    *)
      echo "Unknown reviewer: ${REVIEWER}" >&2
      exit 2
      ;;
  esac
}

plan_project() {
  ensure_dirs
  echo "Blueprint: ${BLUEPRINT}"
  echo "Phases: ${PHASES_DOC}"
  echo "Manager: ${MANAGER}"
  echo "Executor: ${EXECUTOR}"
  echo "Reviewer: ${REVIEWER}"
  echo
  if [[ -f "${PHASES_DOC}" ]]; then
    grep -E '^## F[0-9][0-9]' "${PHASES_DOC}" || true
  fi
}

status_project() {
  ensure_dirs
  echo "Recent events:"
  tail -n 10 "${RUNS_DIR}/events.jsonl" 2>/dev/null || echo "No events yet."
}

run_phase() {
  ensure_dirs
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --phase) PHASE="$2"; shift 2 ;;
      --manager) MANAGER="$2"; shift 2 ;;
      --executor) EXECUTOR="$2"; shift 2 ;;
      --reviewer) REVIEWER="$2"; shift 2 ;;
      --until) UNTIL="$2"; shift 2 ;;
      --dry-run) EXECUTOR="dry-run"; DRY_RUN="true"; shift ;;
      *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
  done

  local phase_content
  phase_content="$(extract_phase_from_docs "${PHASE}")"
  if [[ -z "${phase_content}" ]]; then
    echo "Phase not found: ${PHASE:-first phase}" >&2
    exit 1
  fi

  run_manager "${PHASE}" "${phase_content}"
  local prompt_file
  prompt_file="$(generate_prompt "${PHASE}" "${phase_content}")"
  run_executor "${prompt_file}"
  run_reviewer "${PHASE}"
  log_event "phase-run" "${PHASE:-next} executed with ${EXECUTOR}"
}

close_phase() {
  ensure_dirs
  local phase_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --phase) phase_id="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "${phase_id}" ]]; then
    echo "--phase is required." >&2
    exit 2
  fi

  local summary="${RUNS_DIR}/summaries/${phase_id}.md"
  cat > "${summary}" <<EOF
# Phase ${phase_id} Summary

Status: pending manual review
Date: $(date -Is)

## Summary

Write the final phase summary here.

## Decisions

- TBD

## Pending

- TBD

EOF
  printf '{"ts":"%s","phase":"%s","status":"closed-pending-review","summary":"%s"}\n' "$(date -Is)" "${phase_id}" "${summary}" >> "${RUNS_DIR}/phases.jsonl"
  log_event "close-phase" "${phase_id}"
  echo "Summary created: ${summary}"
}

case "${COMMAND}" in
  init) init_project ;;
  plan) plan_project ;;
  status) status_project ;;
  run) run_phase "$@" ;;
  close-phase) close_phase "$@" ;;
  help|-h|--help) usage ;;
  *) usage; exit 2 ;;
esac
