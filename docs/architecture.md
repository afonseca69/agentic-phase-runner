# Architecture

Agentic Phase Runner separates deterministic orchestration from probabilistic agent work.

## Components

```text
ralph.sh
  deterministic runner

.ai/project-blueprint.yaml
  project-specific execution contract

docs/project-phases.md
  human-readable phase plan

.ai/hooks/*.sh
  neutral guardrails and telemetry helpers

.ai/runs/
  local execution state, ignored by git
```

## Recommended agent roles

```text
manager  = validates phase, gates, and scope
executor = performs one closed task or phase
reviewer = reviews diff, scope, safety, and validation
memory   = stores compact durable summaries
```

## Why a runner instead of prompts only?

Prompts are not a workflow. The runner provides repeatable state transitions:

1. load phase;
2. generate prompt;
3. run manager;
4. run executor;
5. run reviewer;
6. record logs;
7. close phase;
8. stop or continue based on gates.

## Public/private split

Keep this repository generic. Real company policies and project-specific details should live in a private config repository.
