# Developer worker supervision

`worker-supervise.py` starts one developer worker and owns its process group.
It writes an atomic JSON receipt during launch and after completion.
It reads the worker report immediately when the child exits.

Run it synchronously with fresh absolute artifact paths and an existing parent directory.
For example, first create an empty directory for this run.
Then run:

```sh
/usr/bin/python3 "$HOME/.dotfiles/agents/worker-supervise.py" \
  --cwd "$PWD" \
  --log /tmp/example-worker/worker.log \
  --result /tmp/example-worker/result.json \
  --receipt /tmp/example-worker/receipt.json \
  --timeout 600 -- \
  codex exec -o /tmp/example-worker/result.json \
  'Perform the requested work. End with a JSON object containing status and reason. Status must be completed, blocked, or failed.'
```

The worker must write a JSON object with `status` and a nonempty `reason`.
`status` must be `completed`, `blocked`, or `failed`.
The receipt includes the worker exit code and absolute log and report paths.
A zero exit with an absent, malformed, or invalid report returns `unverified`.
An explicit blocked report returns `blocked`, including when the worker exits zero.
A legacy report with a clear leading `Blocked` marker also returns `blocked`.
The supervisor preserves the original report and log.
A timeout returns exit code 124. Cancellation returns 128 plus the signal number.
All terminal paths stop the owned process group, including lingering children after a successful worker exit.
The supervisor does not attach to unrelated process IDs.

The Claude and Codex `PreToolUse` hooks refuse known process-pattern wait loops and detached developer worker launches.
The guard reads directly invoked shell-script files when it can resolve their paths.
It permits one-shot process diagnostics and the supported supervisor command.
This guard checks the developer worker boundary. It cannot prove arbitrary shell code safe.
A session must load the managed hooks before the guard can enforce that boundary.

Run the regression command locally and in CI:

```sh
python3 agents/test_worker_supervise.py
```

The public transcript fixtures contain normalized historical Bash tool inputs and original source-line SHA-256 digests.
The fixtures remove private task content and replace project paths and labels.
The private audit retains exact inputs and an independent replay against the guard.
Its parent session is `054b50d4-fae7-4ed0-bb68-109ad8a2f391`.
The tests deny first-child lines 89, 114, 163, 270, and 2530, plus second-child lines 86, 90, and 132.
The runtime replay uses neutral task labels, replaces the task ID, and reduces the sleep interval.
Three peer watchers continue matching each other after their dummy worker exits.
This reconstructs the recorded three-watcher topology. It proves mutual matching, rather than the transcript's reported self-matching explanation.
A negative control proves that one watcher exits on current BSD `pgrep`, which excludes ancestors.
The blocked-report test retains the recorded blocked marker and Git-index error with a normalized path and a synthetic zero exit.
The transcript did not independently record the blocked worker's exit code.
Other tests exercise missing results, nonzero exits, cancellation, timeout, artifact collisions, and TERM-ignoring descendants.
