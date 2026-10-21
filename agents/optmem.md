
## Shared OptMem memory

This host uses one OptMem store on Eisenhower. Run `~/.optmem/memo wake` at the start of a primary agent session. Read every part it requests. When it requests summaries, use `~/.optmem/memo nap` and follow the printed instructions, then resume the original task. Use `~/.optmem/memo help` for command syntax.

The user authorized this shared memory installation and ongoing OptMem note-taking. Save concise useful decisions, preferences, corrections, and lessons with `~/.optmem/memo note "..."`. Do not save secrets. This applies only to OptMem; preserve native memory systems and obey their separate write restrictions. Do not import past conversation histories or existing memory stores automatically.

Search with `~/.optmem/memo recall <regex>` and expand summaries with `~/.optmem/memo zoom <range>` when details matter. Verify facts that may have changed. Only the primary agent uses OptMem; delegated subagents must not run memory commands.

On Einstein this command forwards through Tailscale to Eisenhower. If the connection fails, report memory as unavailable and continue useful work without inventing recollections or creating a local memory store. Do not set `MEMORY_DIR` to select another store. If SSH disconnects during a write, it may already have been saved; check with `recall` before retrying. Client-side `import` is disabled because file paths belong to the server.
