# Usage Guide

## 1. Initialize a project

```bash
chmod +x ralph.sh .ai/hooks/*.sh
./ralph.sh init
```

This creates local runtime folders and default project phase docs when missing.

## 2. Review the plan

```bash
./ralph.sh plan
```

## 3. Run a safe dry-run phase

```bash
./ralph.sh run --phase F01 --dry-run
```

This writes manager and executor prompts into `.ai/runs/prompts/`.

## 4. Close a phase

```bash
./ralph.sh close-phase --phase F01
```

This writes a summary template into `.ai/runs/summaries/F01.md`.

## 5. Use Codex

```bash
./ralph.sh run --phase F01 --executor codex --reviewer codex
```

Requires `codex` to be installed and authenticated.

## 6. Use Claude

```bash
./ralph.sh run --phase F01 --executor claude
```

Requires `claude` to be installed and authenticated.

## 7. Use a custom adapter

```bash
APR_CUSTOM_EXECUTOR_CMD="./scripts/my-executor.sh" \
  ./ralph.sh run --phase F01 --executor custom
```

The adapter receives the generated prompt file path as the first argument.

## 8. Inspect status

```bash
./ralph.sh status
```

## Notes

- Runtime files under `.ai/runs/` are gitignored.
- The default mode is safe and does not call external AI providers.
- Provider-specific adapters should be added incrementally after validating the base loop.
