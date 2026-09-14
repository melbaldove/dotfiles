# Eisenhower iOS runner

`hosts/eisenhower/github-runner.nix` owns the GitHub Actions runner for
`heyyou/iphone-app-swift`. It runs as `_github-runner`, with UID and GID 533.
The runner has no sudo access or Nix trusted-user grant.

The host uses Determinate Nix. The pinned nix-darwin runner module requires
`nix.enable = true`, so this host declares its launchd service directly.
Check that requirement when updating nix-darwin before replacing this module.

Nix supplies the runner, Node 24, Ruby 3.3, and command-line tools. Xcode 26.3
must exist at `/Applications/Xcode.app`. Apple supplies Xcode and its iOS SDK.
The workflow checks these versions before building. Install the required iOS
platform component with `xcodebuild -downloadPlatform iOS -buildVersion 26.2 -architectureVariant arm64`.
Check the app's generic iOS archive destination as the runner account.
An SDK version check alone does not establish that this destination is available.

## Registration and operation

Build and activate with `sudo darwin-rebuild switch --flake .#eisenhower`.
Provision a short-lived registration token for the repository into
`/var/lib/github-runners/eisenhower-ios/registration-token` with mode 0600
and owner `_github-runner`. Do not put the token in a Nix expression or Git.
The service registers as `eisenhower-ios`, then deletes the token file.
Registration credentials persist in the runner home directory.

Check the service with:

```sh
sudo launchctl print system/org.nixos.github-runner-eisenhower-ios
```

Logs are under `/var/log/github-runners/eisenhower-ios`.
Runner diagnostic logs are under the runner home directory.
Use labels `[self-hosted, macOS, ARM64, eisenhower, ios]` in the workflow.
Only trusted repository code can run here. Labels select the host; they do
not enforce repository or workflow permissions.

## Updates and recovery

Runner self-updates are disabled because Nix owns the package. Update the
flake input and activate a new generation before GitHub rejects an old runner.
Drain the runner before activation to avoid interrupting a build.
Keep the runner name, repository, and work directory stable after registration.
Changing registration settings requires deliberate removal and registration.

The runner home is separate from the personal workspace. DerivedData and gems
remain under that home to reduce repeat build cost. Monitor free disk space.
Remove only runner-owned caches when the service is stopped and no job runs.
Never use the personal checkout as the runner work directory.

To stop the runner, boot out its launchd service. To remove it permanently,
remove the GitHub registration and the host module import, then rebuild.
Preserve state until removal is verified. FileVault can require a console
unlock after restart before the host becomes available.

The Nix activation imports the hash-pinned Apple WWDR G3 intermediate into
the system keychain. The launchd service needs it to validate distribution
signatures. This imports a public intermediate without a trust override.
