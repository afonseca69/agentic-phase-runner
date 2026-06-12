Close the current phase.

Input:
- phase id
- phase name
- executor report
- reviewer result
- files changed
- validation commands
- pending items

Task:
1. Validate whether acceptance criteria were met.
2. Produce a compact phase summary.
3. Identify durable decisions.
4. Identify pending work.
5. Identify risks.
6. Decide whether the next phase may start automatically.
7. Produce a memory-safe record.

Do not include long logs, full diffs, credentials, raw tokens, or discarded intermediate attempts.

Return:
- phase_status
- summary
- decisions
- pending
- risks
- next_phase
- can_continue
- memory_record

