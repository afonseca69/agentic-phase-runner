# Safety Rules

These rules apply to every agent and every execution mode.

## Never do this

Do not execute destructive commands such as:

- migrate:fresh
- migrate:refresh
- db:wipe
- rollback
- reset
- docker compose down -v
- sail down -v
- git push --force
- git clean -fdx
- rm -rf

Do not:

- read, print, copy, summarize, or commit `.env` files;
- expose tokens, API keys, credentials, or secrets;
- deploy without explicit approval;
- call real external APIs unless explicitly allowed;
- change production systems;
- create or modify database schema without explicit approval;
- advance to a risky phase without a human gate.

## Human approval gates

Stop and request approval when the task involves:

- database schema changes;
- authentication or authorization architecture;
- billing or payment integrations;
- real external API calls;
- production deployment;
- destructive commands;
- large architectural changes;
- persistent test failures;
- token, rate, or budget exhaustion.
