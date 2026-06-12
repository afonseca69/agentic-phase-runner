# Guardrails

This folder contains deterministic checks for agentic project execution.

The checks are provider-neutral and can be used with Hermes, Codex, Claude, MiniMax, or any custom runner.

## Contents

- `command-denylist.txt`: command patterns that should stop execution.
- `protected-paths.txt`: file paths that require review before changes.
- `approval-gates.yaml`: generic gates that require human approval.
- `phase-close-checklist.md`: phase completion checklist.
- `review-checklist.md`: reviewer checklist.

Project-specific rules should be added by a private config layer or by the target project.
