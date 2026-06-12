# Simple Project Example

This example validates the Agentic Phase Runner without requiring any AI provider.

It uses the default `dry-run` executor, which writes prompts and logs but does not modify the project.

## Try it

From a clone of this repository:

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

Expected result:

- `.ai/runs/prompts/F01-manager.md` is created.
- `.ai/runs/prompts/F01-executor.md` is created.
- `.ai/runs/summaries/F01.md` is created.
- `.ai/runs/events.jsonl` contains execution events.
