# Agentic Phase Runner

A generic, provider-agnostic phase runner for executing software projects with AI agents.

The goal is simple: turn project documentation into a controlled execution loop with phases, guardrails, memory summaries, token accounting, and pluggable AI agents such as Hermes, Codex, Claude, MiniMax, Gemini, or any custom executor.

This repository is intentionally generic and public-safe. It should not contain private roadmaps, customer data, internal company prompts, runtime logs, local configuration files, or real project memory exports.

## Core idea

```text
project documentation
  ↓
project phases
  ↓
ralph.sh deterministic runner
  ↓
manager / executor / reviewer agents
  ↓
validation, logs, summaries, guardrails, and gates
```

The runner does not replace human judgment. It creates a repeatable loop for AI-assisted project execution.

## Roles

Recommended role split:

```text
Ralph   = deterministic shell runner
Hermes  = governor / manager / phase validator
Codex   = executor or reviewer through `codex exec`
MiniMax = executor through a custom adapter
Claude  = optional executor or reviewer through `claude -p`
Custom  = any other CLI/API adapter
```

## Repository layout

```text
.
├── ralph.sh
├── .ai/
│   ├── templates/
│   │   ├── project-blueprint.yaml
│   │   ├── agents.yaml
│   │   ├── safety-rules.md
│   │   ├── memory-policy.md
│   │   └── token-policy.md
│   ├── guardrails/
│   │   ├── command-denylist.txt
│   │   ├── protected-paths.txt
│   │   ├── approval-gates.yaml
│   │   ├── phase-close-checklist.md
│   │   └── review-checklist.md
│   └── hooks/
│       ├── guard-command.sh
│       ├── guard-files.sh
│       ├── check-phase-gates.sh
│       ├── check-phase-close.sh
│       ├── log-event.sh
│       ├── log-tokens.sh
│       └── notify.sh
├── docs/
└── examples/
    └── simple-project/
```

A real project usually keeps only project-specific files:

```text
project/
├── .ai/project-blueprint.yaml
├── .ai/guardrails/
├── docs/project-description.md
├── docs/project-phases.md
├── AGENTS.md
└── ralph.sh
```

## Commands

```bash
./ralph.sh init
./ralph.sh plan
./ralph.sh status
./ralph.sh run --phase F01 --dry-run
./ralph.sh run --phase F01 --executor codex --reviewer codex
./ralph.sh run --phase F01 --executor claude --reviewer none
./ralph.sh close-phase --phase F01
```

The default executor is `dry-run`, which writes prompts and logs without calling any AI provider.

## Guardrails

The public guardrails layer is generic and reusable:

- `command-denylist.txt` lists command patterns that should stop execution.
- `protected-paths.txt` lists file path patterns that require review.
- `approval-gates.yaml` defines generic approval gates.
- `phase-close-checklist.md` defines minimum checks before closing a phase.
- `review-checklist.md` defines reviewer expectations.

Hooks can be called directly:

```bash
.ai/hooks/guard-command.sh "git status --short"
.ai/hooks/guard-files.sh
.ai/hooks/check-phase-gates.sh F01
.ai/hooks/check-phase-close.sh F01
```

Project-specific guardrails should be provided by a private config repository or by the target project.

## Quick validation

Clone this repository, then run:

```bash
chmod +x ralph.sh .ai/hooks/*.sh
./ralph.sh init
./ralph.sh plan
./ralph.sh run --phase F01 --dry-run
./ralph.sh close-phase --phase F01
./ralph.sh status
```

Expected files:

```text
.ai/runs/events.jsonl
.ai/runs/tokens.jsonl
.ai/runs/phases.jsonl
.ai/runs/prompts/F01-manager.md
.ai/runs/prompts/F01-executor.md
.ai/runs/summaries/F01.md
```

## Validate the simple example

```bash
cp -R examples/simple-project /tmp/apr-simple-project
cp ralph.sh /tmp/apr-simple-project/ralph.sh
cp -R .ai /tmp/apr-simple-project/.ai
cd /tmp/apr-simple-project
chmod +x ralph.sh .ai/hooks/*.sh
./ralph.sh init
./ralph.sh plan
./ralph.sh run --phase F01 --dry-run
./ralph.sh close-phase --phase F01
./ralph.sh status
```

## Custom executors

Use `custom` when you want to connect another model or API wrapper:

```bash
APR_CUSTOM_EXECUTOR_CMD="./scripts/my-executor.sh" \
  ./ralph.sh run --phase F01 --executor custom
```

The custom command receives the generated prompt file path as its first argument.

For reviewers:

```bash
APR_CUSTOM_REVIEWER_CMD="./scripts/my-reviewer.sh" \
  ./ralph.sh run --phase F01 --executor dry-run --reviewer custom
```

## Public/private split

Recommended setup:

```text
agentic-phase-runner          public generic runner
company-agentic-config        private project policies and real blueprints
```

Keep this public repository generic. Put private company rules, real project blueprints, internal prompts, memory records, and integration details in a private repository.

## Safety by default

The runner and templates are designed to be safe by default:

- default executor is `dry-run`;
- protected local files are listed in guardrails;
- destructive commands are blocked by policy;
- production deploys require human approval;
- real external API calls require explicit permission;
- database schema changes should be gated.

## Status

This is an early public template. The first goal is to validate the structure and execution model before adding provider-specific adapters.
