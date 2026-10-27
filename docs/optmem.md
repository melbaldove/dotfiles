# Shared OptMem

Eisenhower owns `~/.optmem/memory`. Einstein and Turing forward `memo` and
`~/.optmem/memo` through OpenSSH to `100.89.96.77:22` on Tailscale, as
`melbournebaldove`. The wrapper ignores SSH configuration files and uses a
pinned host key. Authentication uses the existing default user SSH keys or
agent. There is no LAN or offline store fallback. Turing is a client only;
backups run only on Einstein.

The Home Manager module `users/melbournebaldove/optmem.nix` pins upstream
VictorTaelin/OptMem commit `1fb164cf39028047781f72ac3bb1e5a691c1dcb0`
and its source hash. Nix supplies Python and OpenSSH. The wrapper fixes the
store location and the public command path; upstream instructions therefore
continue to invoke `~/.optmem/memo`. An outer operation lock serializes
all commands, including upstream configuration changes and snapshots.
Upstream's own write lock also protects snapshot creation.

Activation initializes only an absent memory directory. It never imports
old memories. Existing stores remain intact. Agent instructions come from
`agents/optmem.md`, appended only on Eisenhower, Einstein, and Turing. Native memory
systems retain their own policies.

## Use and verify

Run `~/.optmem/memo wake`, `~/.optmem/memo note "a useful fact"`, and
`~/.optmem/memo recall 'useful'` on any of the three hosts. Follow `wake` instructions
for summary creation. Only primary agents use the store. Client `import`
is rejected because its file paths would refer to Eisenhower.

If a connection breaks during a write, inspect `recall` before retrying;
the server may have saved the note already. The wrapper never retries writes.
Eisenhower must be awake and reachable over Tailscale. Battery and lid-closed
availability are separate from installation and require live checks.

Run `python3 -m unittest discover -s scripts -p test_optmem.py` for focused
argument, canonical routing, snapshot restoration, and failed-backup tests.

## Backups and recovery

On Einstein, `optmem-backup` pulls a snapshot over the same Tailscale route.
The `optmem-backup.timer` user timer runs daily and five minutes after the user
service manager starts. Persistent scheduling catches missed calendar runs when the user
manager starts; a failed run waits for the next timer event or manual run.
The user manager must run for scheduling to operate.

Eisenhower creates a temporary archive under both locks, releases them, then
streams the archive. Einstein verifies the archive before atomically publishing
it in `~/.local/state/optmem/backups`, retaining the latest 14 successful
`optmem-*.tar.gz` archives. Failed transfers preserve previous backups.

Inspect `systemctl --user status optmem-backup.timer` and
`journalctl --user -u optmem-backup.service` on Einstein. For a restore drill,
extract an archive into a new empty directory and compare its `memory/LOG.txt`,
`memory/config`, and `memory/TREE` with the captured data. Never point the
production command at the restored test copy. For production recovery, stop
agent writes, preserve the damaged store separately, and restore the selected
archive on Eisenhower before resuming writes. Do not restore while agents run.

Rollback removes the OptMem module import and host-scoped instruction block,
then activates the managed configuration. It removes wrappers and the backup
timer while preserving the writable memory store and backups. Do not delete
those data directories as part of rollback.
