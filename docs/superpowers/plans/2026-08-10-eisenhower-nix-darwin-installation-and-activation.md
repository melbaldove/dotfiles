# Eisenhower Nix and nix-darwin Installation and Activation Plan

> **For Codex:** Use `superpowers:executing-plans` to execute this plan one task at a time. Stop at each explicit authorization gate.

**Goal:** Install a supported multi-user Nix implementation on Eisenhower, transfer the exact approved `.dotfiles` history, create a known nix-darwin baseline generation, and activate commit `5c1557db11e313b7431b3a52bc5644ad3e03eb7b` without losing management access or exposing a credential.

**Architecture:** The signed Determinate macOS package owns Nix, the Nix daemon, the encrypted APFS Nix Store volume, and Nix upgrades. The `.dotfiles` flake owns nix-darwin and the Eisenhower system configuration. This boundary matches `hosts/eisenhower/default.nix`, which sets `nix.enable = false`. A clean Git bundle transfers the approved commit and its history. The first nix-darwin generation uses host-only commit `5e77663ce59cae384da0afd3d3262c4b07c78085`. The second generation uses the complete approved commit. Wired Ethernet and the local physical console protect the cutover from Wi-Fi failure.

**Tech Stack:** macOS 26.3.1 on Apple Silicon, FileVault, APFS, Determinate Nix 3.21.9, Nix flakes, nix-darwin, Home Manager, Git bundles, launchd, `pmset`, and `networksetup`.

---

## Authority and fixed scope

- Planning is the only authorized work for this task.
- Do not install, transfer, activate, reboot, or change Wi-Fi during plan preparation.
- `.dotfiles` is the only configuration owner.
- Do not change `/Users/melbournebaldove/nix-infra`.
- Keep Turing and all unrelated `.dotfiles` worktree changes unchanged.
- Deploy only the approved configuration at `5c1557db11e313b7431b3a52bc5644ad3e03eb7b`.
- Use host-only commit `5e77663ce59cae384da0afd3d3262c4b07c78085` only as the first nix-darwin generation and rollback target.
- The exact target SSID is `Schrödinger’s WiFi`.
- The SHA-256 of the exact UTF-8 SSID bytes is `8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d`.
- macOS preferred-network configuration and the System Keychain remain the only Wi-Fi credential owners.
- Never read, extract, print, copy, store, log, or pass the Wi-Fi password.
- Never add a password argument to `networksetup`.
- Do not inspect the encrypted APFS volume password that the Nix installer keeps in the System Keychain.

## Current verified state

Read-only checks on 2026-08-10 gave this evidence:

| Area | Evidence |
|---|---|
| Identity | `hostname` is `eisenhower.local`; `LocalHostName` is `eisenhower`. |
| Platform | macOS `26.3.1`, `arm64`, `MacBookPro18,1`; SIP is enabled. |
| User | `melbournebaldove`, UID 501, `/bin/zsh`, member of `admin`. |
| Storage | Root is APFS on `/dev/disk3s3s1`; FileVault is on; 223 GiB is available. |
| Backup | Time Machine is not running. `tmutil destinationinfo` reports no configured destination. `tmutil latestbackup` reports a mount failure but can still return exit status 0. |
| Nix | No `nix` command, `/nix`, `/etc/nix/nix.conf`, receipt, daemon, or Nix Store mount exists. |
| nix-darwin | No `darwin-rebuild`, `/run/current-system`, system profile, generation, or nix-darwin launch daemon exists. |
| Repository | `/Users/melbournebaldove/.dotfiles` does not exist on Eisenhower. |
| Management route | Current SSH uses IPv6 link-local addresses on `en0`. The default route and active IPv4 address also use Wi-Fi `en0`. |
| Wired interfaces | `en4`, `en5`, and `en6` exist, but all are inactive and have no IPv4 address. |
| Legacy sleep control | `com.local.nosleep` and `com.aura.caffeinate` are loaded. `pmset` reports `sleep 0` for AC and battery. |
| Wi-Fi contract | The exact target is preferred. `networksetup` reports `-setairportnetwork <device name> <network> [password]`. A password-free live association has not been run because no independent route exists. |

The host is reachable now at `eisenhower.local` and `192.168.50.140`. Reachability can change. Refresh it before each execution session.

## Primary sources

- [Nix 2.34 binary installation](https://nix.dev/manual/nix/2.34/installation/installing-binary.html): macOS uses multi-user installation and an encrypted APFS Nix Store volume when FileVault is enabled.
- [Nix 2.34 uninstallation](https://nix.dev/manual/nix/2.34/installation/uninstall): upstream macOS removal is a manual, multi-step process.
- [Nix 2.34 upgrades](https://nix.dev/manual/nix/2.34/installation/upgrading): upstream multi-user upgrades require package replacement and daemon restart.
- [nix-darwin README](https://github.com/nix-darwin/nix-darwin/blob/master/README.md): Nix and Lix are supported; flakes are recommended; the first install uses `nix run ...#darwin-rebuild -- switch`; nix-darwin has its own uninstaller.
- [nix-darwin `nix.enable` option](https://nix-darwin.github.io/nix-darwin/manual/#opt-nix.enable): `false` stops nix-darwin from managing Nix, the daemon, and `/etc/nix/nix.conf`.
- [Determinate with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/): `nix.enable = false` is a supported ownership boundary.
- [Determinate signed macOS package](https://docs.determinate.systems/guides/mdm/): the package uses Apple Team ID `X3JQ4VPJZ6`; rerunning it upgrades Nix; `/nix/nix-installer uninstall` removes it.
- [Determinate failed-install recovery](https://docs.determinate.systems/troubleshooting/installation-failed-macos/): use the receipt-based uninstaller first; APFS and Keychain cleanup are exceptional recovery actions.
- [Lix installation](https://lix.systems/install/): Lix supports flakes, nix-darwin, and a receipt-based uninstaller.

## Installer comparison

| Installer | Reliability and macOS integration | Uninstall and rollback | Upgrades | Reproducibility | Fit for this flake |
|---|---|---|---|---|---|
| Signed Determinate macOS package | Stable Apple Silicon support. It uses launchd and handles the encrypted APFS store. The package is notarized and signed by Team ID `X3JQ4VPJZ6`. | It keeps `/nix/receipt.json` and `/nix/nix-installer`. The built-in uninstaller is the first recovery path. | Rerun the signed package. Determinate owns `/etc/nix/nix.conf`. | Pin the versioned package URL. Verify its SHA-256, Apple signature, notarization, and Team ID before install. | Best match. The flake already sets `nix.enable = false`, which Determinate documents as supported. |
| Lix Installer | nix-darwin explicitly supports and generally recommends Lix because it has an automated uninstaller. It uses a fork of the same receipt-based installer design. | `/nix/lix-installer uninstall` uses the receipt. | `nix upgrade-nix` is supported, but current macOS daemon-restart guidance is less complete. | Pin the installer and Lix version. The normal path is a downloaded shell installer, not a signed macOS package. | Compatible, but it installs Lix instead of the requested Nix implementation and gives less complete macOS package and upgrade evidence. |
| Upstream Nix multi-user installer | Official upstream Nix. It creates build users, a daemon, an APFS volume, `synthetic.conf`, `fstab`, and a mount daemon. | No automated macOS uninstaller. Removal edits system files and deletes the APFS volume manually. | The official process replaces Nix and restarts the daemon manually. | Version-specific release URLs and hashes are available. | Compatible, but the uninstall and macOS upgrade path is less reliable for this first remote cutover. |

## Recommendation

Use the signed Determinate macOS package at version `v3.21.9`.

The stable package URL resolved to this fixed URL during review:

```text
https://install.determinate.systems/determinate-pkg/tag/v3.21.9/Universal
```

The reviewed artifact has this identity:

```text
SHA-256: 8c74e21dafdcaa0376c4274d3a7c6738964e511fa98fbdd65134475d382c5268
Package ID: systems.determinate.Determinate
Package version: v3.21.9
Apple Team ID: X3JQ4VPJZ6
Signature: Developer ID Installer, trusted Apple timestamp
Notarization: trusted by the Apple notary service
```

This choice gives the clearest APFS, daemon, upgrade, and uninstall boundary on this FileVault host. It also matches the already-reviewed `nix.enable = false` configuration. Do not add the optional Determinate nix-darwin module during this cutover. That would change the approved commit.

## Change classes and hard gates

### Non-disruptive read-only work

- Refresh identity, reachability, disk, FileVault, backup, Nix, nix-darwin, launchd, and network state.
- Verify the installer URL, signature, checksum, and package metadata on the operator machine.
- Verify Git commit identities and build both Darwin systems on the operator machine.
- Inspect the preferred-network identity without printing unrelated networks.

### Low-impact writes with no expected service interruption

- Connect and configure wired Ethernet.
- Complete a Time Machine backup.
- Download the approved package to a temporary directory.
- Transfer the approved Git bundle.
- Install Nix. This changes APFS, launchd, system users, and shell initialization, but it must not change Wi-Fi.
- Build both Darwin generations without activation.

### Disruptive or lockout-capable work

- Run `darwin-rebuild check`. The pinned activation check can test application management and can cause a macOS permission prompt.
- Activate the first nix-darwin generation. It runs shared Darwin, Home Manager, Homebrew, GUI-default, and user-shell activation.
- Activate the complete generation. It starts the Wi-Fi watchdog, which can reassociate Wi-Fi immediately.
- Roll back or uninstall nix-darwin or Nix.
- Restart a managed daemon, reboot, change Wi-Fi state, force disassociation, or stop the access point.
- Retire the two legacy sleep daemons.

No disruptive step can start until all of these conditions are true:

1. A current backup is complete and readable.
2. The wired SSH route works and a new SSH session can use it.
3. The user is physically present at Eisenhower with the lid open, AC power connected, an unlocked administrator session, and Terminal ready.
4. The install and activation window is approved.
5. The package version, hash, Team ID, and downstream Determinate Nix choice are approved.
6. The user accepts that the first activation runs the Homebrew, Home Manager, GUI preference, and shell changes already declared in the approved configuration.

Reboot and Wi-Fi fault tests need a second, explicit outage-window approval.

---

### Task 1: Freeze local source and host evidence

**Files:** No repository changes.

- [ ] **Step 1: Verify the approved commits and pinned inputs locally**

```bash
cd /Users/melbournebaldove/.dotfiles
test "$(git rev-parse 5c1557d)" = 5c1557db11e313b7431b3a52bc5644ad3e03eb7b
test "$(git rev-parse 5e77663)" = 5e77663ce59cae384da0afd3d3262c4b07c78085
git diff --exit-code 4e7049d 5c1557d -- hosts/turing/default.nix
old_turing_output="$(git show 4e7049d:flake.nix |
  sed -n '/darwinConfigurations\."turing"/,/^    };/p')"
new_turing_output="$(git show 5c1557d:flake.nix |
  sed -n '/darwinConfigurations\."turing"/,/^    };/p')"
test "$old_turing_output" = "$new_turing_output"
test "$(git show 5c1557d:flake.lock | jq -r '.nodes.nix-darwin.locked.rev')" = \
  15abb8c98f336cd8bd840d71059adebabe60bf04
test "$(git show 5c1557d:flake.lock | jq -r '.nodes.nixpkgs.locked.rev')" = \
  104240a772428cc2e20d8fd86c9ddbb886bbaff2
test "$(git -C /Users/melbournebaldove/nix-infra rev-parse HEAD)" = \
  8fbd089c09541692eebb673c109d1882a1b1bb8d
test -z "$(git -C /Users/melbournebaldove/nix-infra status --porcelain=v1)"
```

Expected: all commands exit 0. The Turing host file and Turing flake output are unchanged from the pre-Eisenhower source. `nix-infra` remains at its verified clean baseline. Do not include the dirty local `flake.lock`, `hosts/turing/default.nix`, or `codex/AGENTS.md` in the deployment artifact.

- [ ] **Step 2: Refresh live read-only evidence**

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 \
  eisenhower.local '
    hostname
    scutil --get LocalHostName
    sw_vers -productVersion
    uname -m
    sysctl -n hw.model
    id
    fdesetup status
    diskutil info /
    df -h /
    tmutil status
    tmutil latestbackup
    command -v nix || true
    command -v darwin-rebuild || true
    test ! -e /nix
    test ! -e /run/current-system
    route -n get default
    printf "SSH_CONNECTION=%s\n" "$SSH_CONNECTION"
  '
```

Expected: identity and platform match the table. Stop if the host identity differs, free space is less than 50 GiB, FileVault/APFS state differs, Nix is now present, or a current administrator has changed the machine outside this plan.

- [ ] **Step 3: Verify the exact SSID bytes and preferred identity without association**

Run this on Eisenhower. It prints pass states only.

```bash
target='Schrödinger’s WiFi'
test "$(printf '%s' "$target" | shasum -a 256 | awk '{print $1}')" = \
  8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d
iface="$(/usr/sbin/networksetup -listallhardwareports |
  awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}')"
test -n "$iface"
/usr/sbin/networksetup -listpreferredwirelessnetworks "$iface" 2>/dev/null |
  sed '1d; s/^[[:space:]]*//' |
  grep -Fqx -- "$target"
test "$(/usr/sbin/networksetup -help 2>&1 |
  grep -F 'Usage: networksetup -setairportnetwork <device name> <network> [password]' |
  wc -l | tr -d ' ')" = 1
printf 'ssid_hash=PASS preferred_target=PASS networksetup_contract=PASS\n'
```

Expected: one pass line. Do not run `-setairportnetwork` at this stage.

### Task 2: Establish recovery and management gates

**Files:** No repository changes. Live preparation requires user approval.

- [ ] **Step 1: Complete and verify a current backup**

Connect AC power and the Time Machine destination. Unlock or repair the destination in the graphical session if necessary.

```bash
sudo tmutil startbackup --block
tmutil status
tmutil destinationinfo
latest_backup="$(tmutil latestbackup 2>&1)"
case "$latest_backup" in
  /*) ;;
  *) printf 'backup verification failed: %s\n' "$latest_backup" >&2; exit 1 ;;
esac
test -d "$latest_backup"
printf 'latest_backup=%s\n' "$latest_backup"
```

Expected: the backup completes, `Running = 0`, a Time Machine destination is configured, and `latestbackup` returns a current readable absolute path. The current missing destination is a hard blocker. Do not accept only a command exit code because `tmutil latestbackup` returned 0 during review while it printed a mount failure. Open the destination and confirm that Eisenhower's recent user data is present.

- [ ] **Step 2: Establish the independent management route**

Recommended route: connect a trusted USB-C Ethernet adapter or dock to one of `en4`, `en5`, or `en6`. Use a trusted wired network with DHCP. If DHCP is not available, use a direct cable and a dedicated private subnet that does not overlap the Wi-Fi subnet.

```bash
/usr/sbin/networksetup -listallhardwareports
/sbin/ifconfig en4
/usr/sbin/ipconfig getifaddr en4
```

Select the actual active wired interface. From the operator machine, open two SSH sessions to its wired IPv4 address:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 <wired-ip> \
  'hostname; printf "%s\n" "$SSH_CONNECTION"; route -n get default'
```

Expected: `hostname` is `eisenhower.local`, and the server address in `SSH_CONNECTION` is the wired address. Keep one wired session open through each activation. Open a second new wired session after every activation before closing the first one.

The local physical console is a required fallback. Wi-Fi-only SSH is not an independent route. Screen sharing over the same Wi-Fi is also not independent.

- [ ] **Step 3: Record the approved windows and local operator**

Record these facts in the execution log:

```text
backup path and completion time
wired interface and IPv4 address
local operator name
install and activation window start/end
reboot and Wi-Fi outage window start/end, if approved
```

Expected: no password, token, Keychain data, unrelated SSID, BSSID, or nearby-network data enters the log.

### Task 3: Verify and stage the signed Nix package

**Files:** No repository changes. Download to a temporary directory on Eisenhower only after approval.

- [ ] **Step 1: Download the fixed package**

```bash
pkg_stage="$(mktemp -d /var/tmp/determinate-3.21.9.XXXXXX)"
pkg="$pkg_stage/Determinate.pkg"
curl --proto '=https' --tlsv1.2 -sSf -L \
  'https://install.determinate.systems/determinate-pkg/tag/v3.21.9/Universal' \
  -o "$pkg"
```

- [ ] **Step 2: Fail closed on any artifact mismatch**

```bash
test "$(shasum -a 256 "$pkg" | awk '{print $1}')" = \
  8c74e21dafdcaa0376c4274d3a7c6738964e511fa98fbdd65134475d382c5268
spctl -a -vv -t install "$pkg" 2>&1 | tee "$pkg_stage/spctl.txt"
grep -Fq 'origin=Developer ID Installer: Determinate Systems, Inc. (X3JQ4VPJZ6)' \
  "$pkg_stage/spctl.txt"
grep -Fq 'source=Notarized Developer ID' "$pkg_stage/spctl.txt"
pkgutil --check-signature "$pkg"
```

Expected: SHA-256, Team ID, notarization, and Apple trust all match. Stop on any mismatch. Do not replace the pinned package with a newer stable package inside the cutover window.

### Task 4: Install and verify Determinate Nix

**Files:** No repository changes. This task changes the live host.

- [ ] **Step 1: Obtain explicit Nix-install authorization**

Confirm the current backup, local console, pinned artifact, and administrator. This authorization covers APFS volume creation, a native Keychain item for APFS encryption, build users, launchd services, and shell initialization. It does not authorize nix-darwin activation.

- [ ] **Step 2: Install from the local graphical administrator session**

```bash
sudo /usr/sbin/installer -verboseR -pkg "$pkg" -tgt '/'
```

Expected: exit 0. Enter the administrator password only in the native `sudo` prompt. Do not send it through SSH, a variable, a file, a command argument, or a log.

- [ ] **Step 3: Verify Nix ownership and health in a new shell**

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
command -v nix
nix --version
nix config show | grep -E '^(experimental-features|store) ='
test -f /nix/receipt.json
test -x /nix/nix-installer
test -f /etc/nix/nix.conf
sudo launchctl print system/systems.determinate.nix-daemon
mount | grep -F ' on /nix '
diskutil info 'Nix Store'
nix store ping
nix run nixpkgs#hello
```

Expected: Nix works as the normal user through the multi-user daemon. The receipt and uninstaller exist. The encrypted Nix Store is mounted. The Determinate daemon is loaded. Flakes and `nix-command` are enabled. Do not print all Nix configuration or inspect Keychain.

- [ ] **Step 4: Handle an install failure**

If the package fails, stop. Do not start nix-darwin.

```bash
if test -x /nix/nix-installer && test -f /nix/receipt.json; then
  sudo /nix/nix-installer uninstall
fi
```

Expected: the receipt-based uninstaller completes. If `/nix`, the Nix Store volume, or the native volume Keychain item remains, use the official Determinate failed-install recovery guide from the local console. Do not delete an APFS volume or Keychain item without a fresh identifier check and explicit recovery approval.

### Task 5: Transfer the exact approved Git history

**Files:** Create a temporary bare repository and bundle on the operator machine. Create `.dotfiles` on Eisenhower.

- [ ] **Step 1: Build a clean bundle without the local dirty worktree**

Run on the operator machine:

```bash
cd /Users/melbournebaldove/.dotfiles
stage="$(mktemp -d /var/tmp/eisenhower-dotfiles-bundle.XXXXXX)"
git clone --bare . "$stage/repo.git"
git --git-dir="$stage/repo.git" update-ref \
  refs/heads/eisenhower-approved \
  5c1557db11e313b7431b3a52bc5644ad3e03eb7b
git --git-dir="$stage/repo.git" bundle create \
  "$stage/eisenhower-5c1557d.bundle" refs/heads/eisenhower-approved
git bundle verify "$stage/eisenhower-5c1557d.bundle"
git bundle list-heads "$stage/eisenhower-5c1557d.bundle"
shasum -a 256 "$stage/eisenhower-5c1557d.bundle"
```

Expected: the only advertised deployment head is `eisenhower-approved` at the exact full SHA. Git excludes all uncommitted files.

- [ ] **Step 2: Transfer over the wired route**

```bash
scp "$stage/eisenhower-5c1557d.bundle" \
  melbournebaldove@<wired-ip>:/var/tmp/
```

Record the local bundle hash. On Eisenhower, compare it before use:

```bash
shasum -a 256 /var/tmp/eisenhower-5c1557d.bundle
git bundle list-heads /var/tmp/eisenhower-5c1557d.bundle
```

- [ ] **Step 3: Clone without overwriting any host data**

```bash
test ! -e /Users/melbournebaldove/.dotfiles
git clone --branch eisenhower-approved \
  /var/tmp/eisenhower-5c1557d.bundle \
  /Users/melbournebaldove/.dotfiles
cd /Users/melbournebaldove/.dotfiles
git checkout --detach 5c1557db11e313b7431b3a52bc5644ad3e03eb7b
test "$(git rev-parse HEAD)" = 5c1557db11e313b7431b3a52bc5644ad3e03eb7b
test -z "$(git status --porcelain=v1)"
git fsck --full
```

Expected: a clean detached checkout at the exact approved commit. Do not configure a GitHub tracking branch during cutover. The current GitHub `main` does not contain this commit, so an automatic pull is unsafe.

### Task 6: Evaluate and build without activation

**Files:** Create one detached baseline worktree under `/var/tmp`. Do not change the repository.

- [ ] **Step 1: Prove the exact committed configuration**

```bash
cd /Users/melbournebaldove/.dotfiles
test "$(printf '%s' 'Schrödinger’s WiFi' | shasum -a 256 | awk '{print $1}')" = \
  8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d
test "$(nix eval --json .#darwinConfigurations.eisenhower.config.nix.enable)" = false
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.networking.hostName)" = eisenhower
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.nixpkgs.hostPlatform.system)" = aarch64-darwin
PROTECTED_BASELINE_FILE=/var/empty/eisenhower-no-baseline \
  bash hosts/eisenhower/tests/eval-test.sh
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
```

Expected: all Eisenhower evaluation and watchdog tests pass. The explicit nonexistent baseline path prevents a stale local `/tmp` file from affecting this clean deployment test.

- [ ] **Step 2: Create and verify the host-only baseline worktree**

```bash
baseline_parent="$(mktemp -d /var/tmp/eisenhower-host-baseline.XXXXXX)"
baseline_dir="$baseline_parent/worktree"
git worktree add --detach "$baseline_dir" \
  5e77663ce59cae384da0afd3d3262c4b07c78085
test "$(git -C "$baseline_dir" rev-parse HEAD)" = \
  5e77663ce59cae384da0afd3d3262c4b07c78085
test -z "$(git -C "$baseline_dir" status --porcelain=v1)"
test -z "$(git -C "$baseline_dir" ls-tree -r --name-only HEAD |
  grep -E '^hosts/eisenhower/(power\.nix|wifi-watchdog)' || true)"
```

- [ ] **Step 3: Build both generations and compare them**

```bash
baseline_system="$(nix build \
  "$baseline_dir#darwinConfigurations.eisenhower.system" \
  --no-link --print-out-paths)"
full_system="$(nix build \
  /Users/melbournebaldove/.dotfiles#darwinConfigurations.eisenhower.system \
  --no-link --print-out-paths)"
test -x "$baseline_system/activate"
test -x "$full_system/activate"
grep -Fq '5e77663ce59cae384da0afd3d3262c4b07c78085' \
  "$baseline_system/darwin-version.json"
grep -Fq '5c1557db11e313b7431b3a52bc5644ad3e03eb7b' \
  "$full_system/darwin-version.json"
nix store diff-closures "$baseline_system" "$full_system"
```

Expected: both builds complete. The reviewed local build showed that the complete closure adds the two Eisenhower launch daemon property lists and the packaged Wi-Fi watchdog. Stop if the remote closure difference includes Nix ownership, an SSH server change, a credential, or an unrelated host module.

### Task 7: Activation preflight and user-state review

**Files:** No repository changes. This task is inside the approved activation window.

- [ ] **Step 1: Snapshot lockout-sensitive state**

```bash
dscl . -read /Users/melbournebaldove UserShell
sudo systemsetup -getremotelogin
sudo launchctl print system/com.openssh.sshd
sudo launchctl print system/com.local.nosleep
sudo launchctl print system/com.aura.caffeinate
pmset -g custom
ls -ld /Applications /Applications/'Nix Apps' 2>/dev/null || true
```

Expected: Remote Login works, the two legacy sleep jobs are loaded, and the local operator is ready. Save sanitized output only.

- [ ] **Step 2: Review first-activation effects**

The host-only baseline still imports shared Darwin, Home Manager, nix-homebrew, Homebrew, GUI defaults, and all existing Home Manager profiles. Its first activation can:

- change the user shell to the pinned Nix-store `zsh`;
- add system and user profile paths;
- create or replace managed dotfile links, with `.backup` collision files;
- install the declared Homebrew casks and taps;
- change Dock, keyboard, trackpad, and input-source preferences;
- install Nix-managed applications and request App Management permission.

The user must accept this exact scope. If any item is not acceptable, stop. A configuration change and new approved commit are necessary.

- [ ] **Step 3: Run the pinned nix-darwin activation check from the local graphical session**

```bash
nix_bin=/nix/var/nix/profiles/default/bin/nix
nix_darwin_rev=15abb8c98f336cd8bd840d71059adebabe60bf04
sudo "$nix_bin" run \
  "github:nix-darwin/nix-darwin/${nix_darwin_rev}#darwin-rebuild" -- \
  check --flake "$baseline_dir#eisenhower"
```

Expected: `ok`. The pinned `check` runs activation safety checks. It is not a pure build. It can test App Management and require local macOS permission. Stop on an unmanaged `/etc` collision, application-management failure, Home Manager collision, or missing Homebrew prerequisite.

### Task 8: Create the first nix-darwin generation

**Files:** No repository changes. Activate only the host-only baseline.

- [ ] **Step 1: Reconfirm the hard gates**

```bash
test -n "$baseline_system"
test -x "$baseline_system/activate"
ssh -o BatchMode=yes -o ConnectTimeout=5 <wired-ip> hostname
latest_backup="$(tmutil latestbackup 2>&1)"
case "$latest_backup" in /*) ;; *) exit 1 ;; esac
test -d "$latest_backup"
```

Expected: wired SSH and the backup still work. The local operator confirms that the window remains open.

- [ ] **Step 2: Activate the baseline**

```bash
sudo "$nix_bin" run \
  "github:nix-darwin/nix-darwin/${nix_darwin_rev}#darwin-rebuild" -- \
  switch --flake "$baseline_dir#eisenhower"
darwin-rebuild --list-generations
readlink /nix/var/nix/profiles/system
```

Expected: one nix-darwin generation exists and its `darwin-version.json` records `5e77663...`. The legacy sleep jobs remain loaded. No Eisenhower Wi-Fi watchdog exists yet.

- [ ] **Step 3: Prove access before continuing**

Keep the old wired SSH session open. Open a new wired SSH session and a new local Terminal. Verify:

```bash
hostname
id
command -v nix
command -v darwin-rebuild
dscl . -read /Users/melbournebaldove UserShell
sudo systemsetup -getremotelogin
sudo launchctl print system/com.local.nosleep
sudo launchctl print system/com.aura.caffeinate
```

Expected: both new sessions work. Stop and restore from the local console if the shell, SSH, Home Manager, Homebrew, or application changes fail.

### Task 9: Activate the complete approved generation

**Files:** No repository changes. This activation can reassociate Wi-Fi.

- [ ] **Step 1: Check the exact full commit**

```bash
cd /Users/melbournebaldove/.dotfiles
test "$(git rev-parse HEAD)" = 5c1557db11e313b7431b3a52bc5644ad3e03eb7b
test -z "$(git status --porcelain=v1)"
sudo darwin-rebuild check --flake .#eisenhower
```

Expected: `ok`. Stop on any difference from the prior build or any activation check failure.

- [ ] **Step 2: Activate from the wired session while the local operator watches**

```bash
baseline_profile="$(readlink /nix/var/nix/profiles/system)"
printf '%s\n' "$baseline_profile"
sudo darwin-rebuild switch --flake .#eisenhower
darwin-rebuild --list-generations
current_profile="$(readlink /nix/var/nix/profiles/system)"
test "$current_profile" != "$baseline_profile"
grep -Fq '5c1557db11e313b7431b3a52bc5644ad3e03eb7b' \
  "$current_profile/darwin-version.json"
```

Expected: two generations exist. The current generation records the exact approved commit. Keep the old wired session open until immediate verification completes.

- [ ] **Step 3: Verify immediate services and credentials boundary**

```bash
sudo launchctl print system/com.eisenhower.prevent-idle-sleep
sudo launchctl print system/com.eisenhower.wifi-watchdog
pmset -g custom
pmset -g assertions | grep -E 'Prevent(UserIdle)?SystemSleep|com.eisenhower|caffeinate'
sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
sudo launchctl print system/com.eisenhower.wifi-watchdog |
  grep -E 'program|arguments|environment|state|pid'
test ! -e /var/db/eisenhower/wifi-credential
```

Expected: both new jobs are loaded. AC and battery computer sleep are `0`. The managed assertion exists. The watchdog reaches a sanitized state. Its launchd arguments contain only the packaged watchdog program and no credential environment.

Open a new wired SSH session. If the watchdog is not healthy, keep the wired route and local console active. Do not inspect the Keychain. Provision a missing preferred-network credential only through System Settings.

### Task 10: Prove generation rollback before reboot

**Files:** No repository changes.

- [ ] **Step 1: Roll back to the known baseline**

```bash
test "$(darwin-rebuild --list-generations | sed '/^[[:space:]]*$/d' |
  wc -l | tr -d ' ')" -ge 2
sudo darwin-rebuild switch --rollback
test "$(readlink /nix/var/nix/profiles/system)" = "$baseline_profile"
if sudo launchctl print system/com.eisenhower.wifi-watchdog >/dev/null 2>&1; then
  exit 1
fi
sudo launchctl print system/com.local.nosleep
sudo launchctl print system/com.aura.caffeinate
```

Expected: the baseline profile is active, the new watchdog is absent, and both legacy sleep controls remain.

- [ ] **Step 2: Re-activate the proven complete generation**

```bash
cd /Users/melbournebaldove/.dotfiles
sudo darwin-rebuild switch --flake .#eisenhower
test "$(readlink /nix/var/nix/profiles/system)" = "$current_profile"
sudo launchctl print system/com.eisenhower.prevent-idle-sleep
sudo launchctl print system/com.eisenhower.wifi-watchdog
```

Expected: the approved generation and both services return.

### Task 11: Reboot and no-sleep verification

**Files:** No repository changes. This task needs the reboot and Wi-Fi outage window.

- [ ] **Step 1: Reconfirm local and wired recovery, then reboot**

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 <wired-ip> hostname
sudo shutdown -r now
```

Expected after boot: the local console returns, wired SSH returns, `/run/current-system` records the approved commit, and both Eisenhower jobs load before user login. Stop if wired access does not return. Use the physical console for recovery.

- [ ] **Step 2: Verify no idle system sleep on AC and battery**

```bash
pmset -g custom
pmset -g assertions
pmset -g log | tail -200
```

Observe for the approved interval on AC and again on battery. Expected: `sleep 0` for both power sources, the managed assertion remains active, and the log contains no system-sleep transition. Display sleep is not a failure.

- [ ] **Step 3: Verify launchd restart behavior**

```bash
sleep_pid="$(sudo launchctl print system/com.eisenhower.prevent-idle-sleep |
  awk '/pid =/{print $3; exit}')"
sudo kill "$sleep_pid"
sleep 15
sleep_pid_after="$(sudo launchctl print system/com.eisenhower.prevent-idle-sleep |
  awk '/pid =/{print $3; exit}')"
test -n "$sleep_pid_after"
test "$sleep_pid_after" != "$sleep_pid"

watchdog_pid="$(sudo launchctl print system/com.eisenhower.wifi-watchdog |
  awk '/pid =/{print $3; exit}')"
sudo kill "$watchdog_pid"
sleep 35
watchdog_pid_after="$(sudo launchctl print system/com.eisenhower.wifi-watchdog |
  awk '/pid =/{print $3; exit}')"
test -n "$watchdog_pid_after"
test "$watchdog_pid_after" != "$watchdog_pid"
```

Expected: launchd starts a new process for each job. The sleep assertion and watchdog state return.

### Task 12: Verify Wi-Fi reconnect and outage recovery

**Files:** No repository changes. Keep wired SSH and the physical console active.

- [ ] **Step 1: Prove password-free association only inside the outage window**

```bash
iface="$(/usr/sbin/networksetup -listallhardwareports |
  awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}')"
sudo /usr/sbin/networksetup -setairportnetwork "$iface" 'Schrödinger’s WiFi'
```

Expected: exit 0 with no password argument and no credential prompt. Confirm the exact connected network in local System Settings or in the target access point client view. Do not list nearby networks.

- [ ] **Step 2: Verify radio, service, and forced-disconnect recovery**

Before each local fault, arm a three-minute independent failsafe from the local console:

```bash
sudo nohup /bin/sh -c '
  sleep 180
  /sbin/ifconfig "$1" up
  /usr/sbin/networksetup -setnetworkserviceenabled "Wi-Fi" on
  /usr/sbin/networksetup -setairportpower "$1" on
' sh "$iface" >/var/tmp/eisenhower-wifi-failsafe.log 2>&1 &
```

Test radio off and service off one at a time:

```bash
sudo /usr/sbin/networksetup -setairportpower "$iface" off
sleep 40
/usr/sbin/networksetup -getairportpower "$iface"

# Arm a new failsafe before the second fault.
sudo nohup /bin/sh -c '
  sleep 180
  /sbin/ifconfig "$1" up
  /usr/sbin/networksetup -setnetworkserviceenabled "Wi-Fi" on
  /usr/sbin/networksetup -setairportpower "$1" on
' sh "$iface" >/var/tmp/eisenhower-wifi-failsafe.log 2>&1 &
sudo /usr/sbin/networksetup -setnetworkserviceenabled 'Wi-Fi' off
sleep 40
/usr/sbin/networksetup -getnetworkserviceenabled 'Wi-Fi'
sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
```

Also disconnect only Eisenhower from the target access point. Expected: the watchdog restores the service and radio, retries the exact target, and returns to `healthy`. Do not remove the preferred credential.

- [ ] **Step 3: Verify access-point outage, repeated failure, and backoff**

Stop the target access point during the approved window. Observe sanitized data only:

```bash
log stream --style compact \
  --predicate 'eventMessage CONTAINS "component=wifi-watchdog"'
while :; do
  date -u '+%Y-%m-%dT%H:%M:%SZ'
  sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
  sleep 2
done
```

Expected retry delays: `5, 10, 20, 40, 60, 120, 300, 300` seconds. Restore the access point. Expected: recovery within 300 seconds plus association time, then failure count and delay reset.

- [ ] **Step 4: Audit the live secret boundary**

```bash
ps axww -o pid=,command= | grep -F eisenhower-wifi-watchdog | grep -v grep
sudo launchctl print system/com.eisenhower.wifi-watchdog
test ! -e /var/db/eisenhower/wifi-credential
unexpected="$(sudo /bin/ls -1A /var/db/eisenhower |
  grep -Fvx 'wifi-watchdog.status' || true)"
test -z "$unexpected"
if sudo grep -R -n -E \
  'find-generic-password|dump-keychain|wifi-credential|password=' \
  /var/db/eisenhower \
  /var/log/eisenhower-wifi-watchdog.log \
  /var/log/eisenhower-wifi-watchdog.error.log 2>/dev/null; then
  exit 1
fi
```

Expected: no credential file, credential environment, Keychain extraction command, or password-bearing log exists. Never search for the password value.

### Task 13: Retire legacy jobs only after complete proof

**Files:** No repository changes. Move files; do not delete them.

- [ ] **Step 1: Require all evidence**

Required: exact builds, activation check, baseline generation, full generation, generation rollback, reboot, AC and battery no-sleep observation, launchd restart, password-free association, forced disconnect, radio/service recovery, access-point outage/backoff/recovery, and secret audit.

If the user defers a fault test, keep both legacy jobs loaded.

- [ ] **Step 2: Move the legacy property lists after explicit approval**

```bash
backup_dir="/Library/LaunchDaemons.disabled/eisenhower-$(date +%Y%m%d-%H%M%S)"
sudo mkdir -p "$backup_dir"
sudo launchctl bootout system \
  /Library/LaunchDaemons/com.local.nosleep.plist 2>/dev/null || true
sudo launchctl bootout system \
  /Library/LaunchDaemons/com.aura.caffeinate.plist 2>/dev/null || true
sudo mv /Library/LaunchDaemons/com.local.nosleep.plist "$backup_dir/"
sudo mv /Library/LaunchDaemons/com.aura.caffeinate.plist "$backup_dir/"
printf '%s\n' "$backup_dir" |
  sudo tee /var/db/eisenhower/retired-sleep-jobs-path >/dev/null
sudo launchctl print system/com.eisenhower.prevent-idle-sleep
pmset -g custom
pmset -g assertions
```

Expected: both old property lists remain recoverable in the timestamped directory. The managed no-sleep controls remain effective.

## Rollback and uninstall runbook

### Failure before first nix-darwin activation

If Nix works but the flake does not build, leave Nix installed and fix the source in a separate approved commit. No system generation exists.

If Nix itself must be removed:

```bash
sudo /nix/nix-installer uninstall
```

Run this from the local console. Verify the daemon, receipt, Nix Store mount, and `/etc/nix` are absent. Follow the official failed-install recovery guide only for verified remnants.

### Failure after baseline or full activation

Do not uninstall Nix first. nix-darwin can leave `/etc`, the user shell, and profiles linked into `/nix`.

1. Use `sudo darwin-rebuild switch --rollback` to return from full to baseline.
2. If abandoning nix-darwin, run its uninstaller while Nix still works:

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run \
  'github:nix-darwin/nix-darwin/15abb8c98f336cd8bd840d71059adebabe60bf04#darwin-uninstaller'
```

3. Verify that `/run/current-system` and the system generation links are gone.
4. Verify that `melbournebaldove` has a valid native shell. Restore `/bin/zsh` from the local console if required.
5. Verify Remote Login and native `/etc` files.
6. If the legacy sleep jobs were retired, restore them before Nix removal:

```bash
backup_dir="$(sudo cat /var/db/eisenhower/retired-sleep-jobs-path)"
test -d "$backup_dir"
sudo mv "$backup_dir/com.local.nosleep.plist" /Library/LaunchDaemons/
sudo mv "$backup_dir/com.aura.caffeinate.plist" /Library/LaunchDaemons/
sudo launchctl bootstrap system \
  /Library/LaunchDaemons/com.local.nosleep.plist
sudo launchctl bootstrap system \
  /Library/LaunchDaemons/com.aura.caffeinate.plist
```

7. Verify the two legacy jobs and `pmset` state.
8. Only then run `sudo /nix/nix-installer uninstall`.
9. Reboot only after the local console confirms that the native shell and system files work.

nix-darwin rollback and uninstallation do not automatically reverse all Homebrew cask installs, GUI defaults, or Home Manager backup files. Restore those items from the verified backup or from an approved item-by-item restoration list. Do not use a broad worktree or home-directory reset.

### Self-lockout response

- Keep the physical console logged in and one old wired SSH session open.
- Do not close a working session until a new wired session succeeds.
- If the shell fails, use the local administrator session to restore `/bin/zsh`.
- If SSH fails, recover locally. Do not change Wi-Fi as the first recovery action.
- If the full watchdog causes a network problem, roll back to the baseline generation over wired Ethernet.
- If generation rollback fails, activate the saved baseline system path directly with its `activate` script only from the local console and only after a fresh path check.

## Post-cutover ownership and upgrades

- Determinate owns Nix, its daemon, `/etc/nix/nix.conf`, the Nix Store volume, and Nix upgrades.
- nix-darwin owns the active system generations but does not manage Nix because `nix.enable = false`.
- Upgrade Determinate only with a newly pinned package URL, SHA-256, Apple signature, notarization result, and Team ID check. Rerun the signed package as its documentation specifies.
- Upgrade nix-darwin, Nixpkgs, or Home Manager only through a reviewed `.dotfiles` lock-file commit. Build it before activation and retain a known generation.
- Do not add Nix settings under nix-darwin while `nix.enable = false`. If custom Determinate settings become necessary, design their ownership separately.

## Critical and Important review

### Critical controls

- Eisenhower has no configured Time Machine destination. Nix installation is blocked until a current readable backup exists.
- Current remote management uses Wi-Fi. Activation is blocked until wired SSH and the physical console are ready.
- The first activation is not a small host-only change. It runs shared Homebrew, Home Manager, GUI-default, and shell activation. The user must authorize that scope.
- The full activation starts a Wi-Fi association watchdog. It needs the independent route and approved window even if no explicit Wi-Fi test follows.
- Nix removal must occur after nix-darwin removal. Reversing this order can leave native system paths linked into a removed Nix store.
- The package, Git bundle, and flake inputs are pinned and verified before use.
- No command reads or passes a Wi-Fi password.

### Important controls

- The signed Determinate package is recommended even though nix-darwin generally recommends Lix. Eisenhower's existing `nix.enable = false` configuration exactly matches Determinate's documented integration, and the signed macOS package gives stronger package, upgrade, and APFS evidence for this host.
- `darwin-rebuild check` is not a pure build. Run it only in the activation window with the graphical operator present.
- The approved commit is not on the current GitHub `main`. Use the verified Git bundle. Do not pull or push during cutover.
- Build and identify both exact system closures before the first activation.
- Keep the legacy sleep jobs until all reboot and fault evidence passes.
- Keep one consistent term for the target SSID and one fixed UTF-8 hash.
- Treat live reachability as time-sensitive. Refresh it before each task.

No Critical or Important design gap remains in the plan. Execution remains blocked by the backup and independent-management-route gates, and by the explicit authorizations listed below.

## Required decisions and authorizations

Before execution, the user must explicitly provide these decisions:

1. Approve Determinate Nix `v3.21.9` and the pinned signed-package identity above.
2. Approve a current Time Machine backup as the prerequisite backup. Configure, mount, and complete the destination first.
3. Approve and arrange wired Ethernet plus physical presence at Eisenhower.
4. Approve transfer of the exact commit through a verified Git bundle because the commit is not on GitHub `main`.
5. Approve the first-activation effects from shared Homebrew, Home Manager, GUI preferences, and the Nix-managed user shell.
6. Approve the install and first-activation maintenance window.
7. Separately approve the reboot and Wi-Fi outage window, including impact on other access-point users.

No Wi-Fi password or Keychain access authorization is required.
