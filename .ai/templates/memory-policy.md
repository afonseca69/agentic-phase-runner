# Memory Policy

## Permanent memory

Save only compact, durable information:

- project name;
- completed phase;
- checkpoint or commit reference;
- architectural decisions;
- pending items;
- risks;
- next recommended phase;
- important constraints.

## Never save

Do not save:

- full logs;
- complete prompts;
- complete diffs;
- long test outputs;
- credentials or secrets;
- `.env` content;
- raw token values;
- discarded intermediate attempts.

## Phase close procedure

At phase close:

1. Write a compact summary.
2. Store it in `.ai/runs/summaries/`.
3. Optionally save a durable memory record using the configured memory provider.
4. Discard temporary context.
5. Continue only if the blueprint and safety gates allow it.
