# Token Policy

Before each phase:

- estimate complexity as low, medium, or high;
- split high-complexity work into smaller tasks;
- avoid sending long logs to agents;
- send only the context required for the task.

If an agent fails because of token, rate, or budget limits:

1. Stop the current attempt.
2. Save a compact state summary.
3. Inspect the repository diff.
4. Switch to the fallback agent if configured.
5. Send only the compact state to the fallback.
6. If the fallback also fails, stop and report.

Never continue after suspected context truncation without a checkpoint summary.
