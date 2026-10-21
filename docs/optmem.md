# Shared OptMem

Eisenhower owns `~/.optmem/memory`. Einstein forwards `memo` and
`~/.optmem/memo` through OpenSSH to `100.89.96.77:22` on Tailscale, as
`melbournebaldove`. The wrapper ignores SSH configuration files and uses a
pinned host key. Authentication uses the existing default user SSH keys or
agent. There is no LAN or offline store fallback. Turing is unchanged.

The Home Manager module `users/melbournebaldove/optmem.nix` pins upstream
VictorTaelin/OptMem commit `1fb164cf39028047781f72ac3bb1e5a691c1dcb0`
and its source hash. Nix supplies Python and OpenSSH. The wrapper fixes the
store location and the public command path; upstream instructions therefore
continue to invoke `~/.optmem/memo`. An outer operation lock serializes
all commands, including upstream configuration changes and snapshots.
Upstream's own write lock also protects snapshot creation.

Activation initializes only an absent memory directory. It never imports
old memories. Existing stores remain intact. Agent instructions come from
`agents/optmem.md`, appended only on Eisenhower and Einstein. Native memory
systems retain their own policies.

## Scoped deployment

Build on the matching host from this repository:

```sh
nix build --impure --file nix/optmem-deploy.nix --argstr system aarch64-darwin --argstr host eisenhower --out-link /tmp/optmem-result
python3 scripts/activate-optmem.py /tmp/optmem-result
```

On Einstein, use `x86_64-linux` and `einstein`. Run activation with the Nix
Python used by the generated command if Python is not on PATH. This installs
only the selected OptMem files and generated agent instructions. It does not
activate a minimal Home Manager generation or rebuild the host system.
The activation script records previous symlinks under
`~/.local/state/optmem/deployments/<timestamp>/links.json` and retains the
deployment closure with a Nix garbage-collection root beside that receipt.

Eisenhower's next full rebuild must use this repository revision or newer.
Einstein's `nix-infra` flake must pin a dotfiles revision containing this change
before a full rebuild; an older pin can replace the agent instructions with
the older version. Reapply the scoped deployment after such a rebuild.

## Use and verify

Run `~/.optmem/memo wake`, `~/.optmem/memo note "a useful fact"`, and
`~/.optmem/memo recall 'useful'` on either host. Follow `wake` instructions
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

To roll back a scoped deployment without a host rebuild, run
`python3 scripts/activate-optmem.py --rollback <receipt>/links.json` on that
host. It refuses to overwrite links changed since that deployment. On Einstein
it stops the backup timer and service before restoring the previous links.
