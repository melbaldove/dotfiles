# Eisenhower Connectivity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Eisenhower as a separate nix-darwin host that cannot enter idle system sleep and continuously retries the preferred Wi-Fi network `Schrödinger’s WiFi` without accessing its password.

**Architecture:** `.dotfiles` owns a second Darwin assembly at `darwinConfigurations.eisenhower`. Host-specific power and Wi-Fi modules remain under `hosts/eisenhower/`. A root launch daemon runs a password-free `networksetup` watchdog. macOS preferred-network configuration and the System Keychain remain the sole credential owners.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, launchd, Bash, `networksetup`, `ifconfig`, `ipconfig`, `pmset`, `caffeinate`, and the macOS unified log.

---

## Locked constraints

- Work only in `/Users/melbournebaldove/.dotfiles`.
- Do not modify `/Users/melbournebaldove/nix-infra`.
- Keep `darwinConfigurations.turing` and `hosts/turing/default.nix` unchanged.
- Preserve existing changes to `codex/AGENTS.md`, `flake.lock`, and `hosts/turing/default.nix`.
- Use the exact SSID `Schrödinger’s WiFi`.
- Require SHA-256 `8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d` for the exact SSID UTF-8 bytes.
- Never read, extract, store, decrypt, log, or pass the Wi-Fi password.
- Never call a Keychain secret-reading command.
- Associate with only `networksetup -setairportnetwork <device> 'Schrödinger’s WiFi'`.
- Keep `com.local.nosleep` and `com.aura.caffeinate` until replacement proof passes.
- Do not run disruptive Wi-Fi tests through the only management connection.

## Source baseline and file map

The current working flake exposes only Turing. A prior live check confirmed that `networksetup` reports `-setairportnetwork <device name> <network> [password]` and that the target is preferred. Eisenhower is currently unreachable at `eisenhower.local`. Treat this as a live execution condition. Recheck reachability and the native command contract before any live step. Static design review and local implementation can continue while the host is unreachable. Eisenhower will reuse `modules/system/darwin/default.nix`, `modules/system/darwin/gui.nix`, and the existing `core.nix`, `dev.nix`, `desktop.nix`, and `emacs.nix` Home Manager profiles. It will not import the unrelated agenix or WireGuard modules.

- Modify `flake.nix`: add the Eisenhower output.
- Create `hosts/eisenhower/default.nix`: assemble the host and user profiles.
- Create `hosts/eisenhower/power.nix`: declare the sleep policy and assertion daemon.
- Create `hosts/eisenhower/wifi-watchdog.sh`: implement reconnect behavior.
- Create `hosts/eisenhower/wifi-watchdog.nix`: package and launch the watchdog.
- Create `hosts/eisenhower/tests/wifi-watchdog-test.sh`: test the state machine with fake tools.
- Create `hosts/eisenhower/tests/eval-test.sh`: test both Darwin outputs and Turing isolation.
- Modify `README.md`: document the separate Eisenhower command.

### Task 1: Record the dirty-worktree baseline

**Files:** Read `AGENTS.md`, `flake.nix`, `hosts/turing/default.nix`, and the approved spec.

- [ ] **Step 1: Confirm the approved source and worktree**

```bash
cd /Users/melbournebaldove/.dotfiles
git show --no-patch --oneline b4c0bfc
git status --short --branch
```

Expected: the approved spec exists and the three unrelated modified files remain visible.

- [ ] **Step 2: Record immutable baselines outside the repository**

```bash
shasum -a 256 codex/AGENTS.md flake.lock hosts/turing/default.nix \
  > /tmp/eisenhower-protected-files.sha256
sed -n '/darwinConfigurations\."turing"/,/^    };/p' flake.nix |
  shasum -a 256 > /tmp/eisenhower-turing-flake-output.sha256
git status --porcelain=v1 > /tmp/eisenhower-preimplementation-status.txt
git -C /Users/melbournebaldove/nix-infra rev-parse HEAD > /tmp/eisenhower-nix-infra-head
git -C /Users/melbournebaldove/nix-infra status --porcelain=v1 \
  > /tmp/eisenhower-nix-infra-status.txt
```

Expected: three protected-file hashes, one Turing output hash, one `nix-infra` revision, and an empty `nix-infra` status file.

### Task 2: Add Eisenhower as a separate Darwin assembly

**Files:** Modify `flake.nix`; create `hosts/eisenhower/default.nix` and `hosts/eisenhower/tests/eval-test.sh`.

- [ ] **Step 1: Write the failing host test**

Create `hosts/eisenhower/tests/eval-test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
baseline_file="${PROTECTED_BASELINE_FILE:-/tmp/eisenhower-protected-files.sha256}"
if [[ -f "$baseline_file" ]]; then shasum -a 256 -c "$baseline_file"; fi
test "$(printf '%s' 'Schrödinger’s WiFi' | shasum -a 256 | awk '{print $1}')" = \
  8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d
test "$(nix eval --raw .#darwinConfigurations.turing.config.networking.hostName)" = turing
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.networking.hostName)" = eisenhower
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.nixpkgs.hostPlatform.system)" = aarch64-darwin
echo "Darwin host boundary: PASS"
```

- [ ] **Step 2: Verify the test fails because Eisenhower is absent**

```bash
bash hosts/eisenhower/tests/eval-test.sh
```

Expected: Turing hash passes, then evaluation fails on the missing Eisenhower output.

- [ ] **Step 3: Create `hosts/eisenhower/default.nix`**

```nix
{ inputs, pkgs, ... }:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../../modules/system/darwin/default.nix
    ../../modules/system/darwin/gui.nix
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; self = inputs.self; };
    users.melbournebaldove.imports = [
      ../../users/melbournebaldove/core.nix
      ../../users/melbournebaldove/dev.nix
      ../../users/melbournebaldove/desktop.nix
      ../../users/melbournebaldove/emacs.nix
    ];
  };
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 6;
  system.primaryUser = "melbournebaldove";
  nixpkgs = {
    hostPlatform.system = "aarch64-darwin";
    config.allowUnfree = true;
  };
  networking.hostName = "eisenhower";
  security.pam.services.sudo_local.touchIdAuth = true;
  environment.systemPackages = with pkgs; [ vim coreutils findutils jq tmux curl wget ];
  environment.variables.PUPPETEER_EXECUTABLE_PATH =
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
  nix.enable = false;
}
```

- [ ] **Step 4: Add the sibling flake output without editing Turing**

```nix
    darwinConfigurations."eisenhower" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs self; };
      modules = [ ./hosts/eisenhower/default.nix ];
    };
```

- [ ] **Step 5: Run the host test and commit exact paths**

```bash
bash hosts/eisenhower/tests/eval-test.sh
git add flake.nix hosts/eisenhower/default.nix hosts/eisenhower/tests/eval-test.sh
git diff --cached --check
git diff --cached --name-only
git commit -m "feat(darwin): add Eisenhower host assembly"
git rev-parse HEAD > /tmp/eisenhower-host-baseline-commit
```

Expected: test `PASS`; Turing and `flake.lock` are not staged. The recorded commit contains the host assembly but no Eisenhower power or Wi-Fi controls. It is the known first-generation rollback target.

### Task 3: Add declarative sleep prevention

**Files:** Create `hosts/eisenhower/power.nix`; modify Eisenhower assembly and evaluation test.

- [ ] **Step 1: Add failing assertions before the test's final `echo`**

```bash
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.power.sleep.computer)" = never
test "$(nix eval --json .#darwinConfigurations.eisenhower.config.power.sleep.allowSleepByPowerButton)" = false
power_job="$(nix eval --json .#darwinConfigurations.eisenhower.config.launchd.daemons.eisenhower-prevent-idle-sleep.serviceConfig)"
jq -e '.Label == "com.eisenhower.prevent-idle-sleep"' <<<"$power_job" >/dev/null
jq -e '.ProgramArguments == ["/usr/bin/caffeinate", "-i"]' <<<"$power_job" >/dev/null
jq -e '.RunAtLoad == true and .KeepAlive == true' <<<"$power_job" >/dev/null
```

- [ ] **Step 2: Run and confirm the missing-policy failure**

```bash
bash hosts/eisenhower/tests/eval-test.sh
```

- [ ] **Step 3: Create `hosts/eisenhower/power.nix`**

```nix
{
  power.sleep = {
    computer = "never";
    allowSleepByPowerButton = false;
  };
  launchd.daemons.eisenhower-prevent-idle-sleep.serviceConfig = {
    Label = "com.eisenhower.prevent-idle-sleep";
    ProgramArguments = [ "/usr/bin/caffeinate" "-i" ];
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Background";
    ThrottleInterval = 30;
    StandardOutPath = "/var/log/eisenhower-prevent-idle-sleep.log";
    StandardErrorPath = "/var/log/eisenhower-prevent-idle-sleep.error.log";
  };
}
```

- [ ] **Step 4: Import, test, and commit**

Add `./power.nix` only to Eisenhower, then run:

```bash
bash hosts/eisenhower/tests/eval-test.sh
git add hosts/eisenhower/default.nix hosts/eisenhower/power.nix hosts/eisenhower/tests/eval-test.sh
git diff --cached --check
git commit -m "feat(eisenhower): prevent idle system sleep"
```

Expected: test `PASS`; Turing remains unstaged.

### Task 4: Specify and implement the reconnect watchdog

**Files:** Create `hosts/eisenhower/wifi-watchdog.sh` and `hosts/eisenhower/tests/wifi-watchdog-test.sh`.

- [ ] **Step 1: Write the failing isolated test**

Create `hosts/eisenhower/tests/wifi-watchdog-test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
fake_bin="$test_dir/bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/networksetup" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  -listallhardwareports) printf 'Hardware Port: Wi-Fi\nDevice: en7\n' ;;
  -listpreferredwirelessnetworks)
    printf 'Preferred networks on %s:\n' "$2"
    [[ "${FAKE_PREFERRED:-yes}" == yes ]] && printf '\tSchrödinger’s WiFi\n' || printf '\tUnrelated Network\n'
    ;;
  -getnetworkserviceenabled) printf '%s\n' "${FAKE_SERVICE_STATE:-Enabled}" ;;
  -setnetworkserviceenabled|-setairportpower) printf '%s\n' "$*" >>"$FAKE_CALLS" ;;
  -getairportpower) printf 'Wi-Fi Power (%s): %s\n' "$2" "${FAKE_RADIO_STATE:-On}" ;;
  -setairportnetwork)
    printf '%s\n' "$#" >"$FAKE_ASSOC_ARGC"
    printf '%s\n' "$@" >"$FAKE_ASSOC_ARGS"
    [[ "${FAKE_ASSOC_RESULT:-success}" == success ]]
    ;;
  *) exit 64 ;;
esac
SH
cat >"$fake_bin/ifconfig" <<'SH'
#!/usr/bin/env bash
[[ "${FAKE_LINK_STATE:-active}" == active ]] && printf 'status: active\n' || printf 'status: inactive\n'
SH
cat >"$fake_bin/ipconfig" <<'SH'
#!/usr/bin/env bash
[[ "${FAKE_ADDRESS_STATE:-ready}" == ready ]] && printf '192.0.2.10\n'
SH
cat >"$fake_bin/logger" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$FAKE_LOG"
SH
cat >"$fake_bin/sleep" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$1" >>"$FAKE_SLEEPS"
if [[ -n "${FAKE_SLEEP_LIMIT:-}" ]]; then
  count="$(wc -l <"$FAKE_SLEEPS" | tr -d ' ')"
  if (( count >= FAKE_SLEEP_LIMIT )); then exit 99; fi
fi
SH
chmod +x "$fake_bin"/*

watchdog="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wifi-watchdog.sh"
expected_ssid_sha256='8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d'
actual_ssid="$(sed -n "s/^readonly target_ssid='\\(.*\\)'$/\\1/p" "$watchdog")"
test "$(printf '%s' "$actual_ssid" | shasum -a 256 | awk '{print $1}')" = \
  "$expected_ssid_sha256"
export EISENHOWER_NETWORKSETUP="$fake_bin/networksetup"
export EISENHOWER_IFCONFIG="$fake_bin/ifconfig"
export EISENHOWER_IPCONFIG="$fake_bin/ipconfig"
export EISENHOWER_LOGGER="$fake_bin/logger"
export EISENHOWER_SLEEP="$fake_bin/sleep"
export EISENHOWER_STATUS_FILE="$test_dir/status"
export FAKE_CALLS="$test_dir/calls" FAKE_ASSOC_ARGC="$test_dir/argc"
export FAKE_ASSOC_ARGS="$test_dir/args" FAKE_LOG="$test_dir/log" FAKE_SLEEPS="$test_dir/sleeps"

reset_case() {
  : >"$FAKE_CALLS"; : >"$FAKE_LOG"; : >"$FAKE_SLEEPS"
  rm -f "$FAKE_ASSOC_ARGC" "$FAKE_ASSOC_ARGS" "$EISENHOWER_STATUS_FILE"
  export FAKE_PREFERRED=yes FAKE_SERVICE_STATE=Enabled FAKE_RADIO_STATE=On
  export FAKE_LINK_STATE=active FAKE_ADDRESS_STATE=ready FAKE_ASSOC_RESULT=success
}

reset_case
bash "$watchdog" --once
test "$(cat "$FAKE_ASSOC_ARGC")" = 3
test "$(sed -n '1p' "$FAKE_ASSOC_ARGS")" = -setairportnetwork
test "$(sed -n '2p' "$FAKE_ASSOC_ARGS")" = en7
test "$(sed -n '3p' "$FAKE_ASSOC_ARGS")" = "$actual_ssid"
test "$(wc -l <"$FAKE_ASSOC_ARGS" | tr -d ' ')" = 3
grep -Fq 'state=healthy' "$EISENHOWER_STATUS_FILE"

reset_case
export FAKE_PREFERRED=no
if bash "$watchdog" --once; then exit 1; fi
test ! -e "$FAKE_ASSOC_ARGS"
grep -Fq 'state=credential_unavailable' "$EISENHOWER_STATUS_FILE"
if grep -Fq 'Unrelated Network' "$FAKE_LOG"; then exit 1; fi

reset_case
export FAKE_ASSOC_RESULT=failure
if bash "$watchdog" --once; then exit 1; fi
grep -Fq 'state=authentication_failed' "$EISENHOWER_STATUS_FILE"

reset_case
export FAKE_ASSOC_RESULT=failure FAKE_SLEEP_LIMIT=8
set +e
bash "$watchdog"
watchdog_exit="$?"
set -e
test "$watchdog_exit" = 99
test "$(paste -sd, "$FAKE_SLEEPS")" = '5,10,20,40,60,120,300,300'
grep -Fq 'state=authentication_failed' "$FAKE_LOG"
unset FAKE_SLEEP_LIMIT

reset_case
export FAKE_RADIO_STATE=Off
bash "$watchdog" --once
grep -Fq -- '-setairportpower en7 on' "$FAKE_CALLS"

reset_case
export FAKE_LINK_STATE=inactive
if bash "$watchdog" --wait-healthy en7; then exit 1; fi
test "$(paste -sd, "$FAKE_SLEEPS")" = 1

expected=(5 10 20 40 60 120 300 300)
for index in "${!expected[@]}"; do
  test "$(bash "$watchdog" --print-backoff "$((index + 1))")" = "${expected[$index]}"
done
if grep -R -n -E 'find-generic-password|password=' "$watchdog" "$FAKE_LOG"; then exit 1; fi
echo "Wi-Fi watchdog tests: PASS"
```

- [ ] **Step 2: Run and confirm the missing-script failure**

```bash
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
```

- [ ] **Step 3: Create `hosts/eisenhower/wifi-watchdog.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1112 # U+2019 is required by the approved SSID.
readonly target_ssid='Schrödinger’s WiFi'
readonly network_service='Wi-Fi'
readonly healthy_interval=30
readonly reassert_interval=300
networksetup_bin="${EISENHOWER_NETWORKSETUP:-/usr/sbin/networksetup}"
ifconfig_bin="${EISENHOWER_IFCONFIG:-/sbin/ifconfig}"
ipconfig_bin="${EISENHOWER_IPCONFIG:-/usr/sbin/ipconfig}"
logger_bin="${EISENHOWER_LOGGER:-/usr/bin/logger}"
sleep_bin="${EISENHOWER_SLEEP:-/bin/sleep}"
status_file="${EISENHOWER_STATUS_FILE:-/var/db/eisenhower/wifi-watchdog.status}"
last_state=command_failed
last_asserted_at=0

backoff_for() {
  case "$1" in 1) echo 5;; 2) echo 10;; 3) echo 20;; 4) echo 40;;
    5) echo 60;; 6) echo 120;; *) echo 300;; esac
}
write_status() {
  local state="$1" failures="$2" delay="$3" tmp
  umask 077; mkdir -p "$(dirname "$status_file")"; tmp="${status_file}.$$"
  printf 'state=%s\nfailures=%s\nnext_retry_seconds=%s\nupdated_at=%s\n' \
    "$state" "$failures" "$delay" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$tmp"
  mv -f "$tmp" "$status_file"
  "$logger_bin" -t com.eisenhower.wifi-watchdog \
    "component=wifi-watchdog state=$state failures=$failures next_retry_seconds=$delay" \
    >/dev/null 2>&1 || true
}
wifi_device() {
  "$networksetup_bin" -listallhardwareports 2>/dev/null |
    awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}'
}
target_is_preferred() {
  "$networksetup_bin" -listpreferredwirelessnetworks "$1" 2>/dev/null |
    sed '1d; s/^[[:space:]]*//' | grep -Fqx -- "$target_ssid"
}
link_is_active() { "$ifconfig_bin" "$1" 2>/dev/null | grep -Fq 'status: active'; }
wait_healthy_interval() {
  local device="$1"
  for _ in {1..30}; do
    "$sleep_bin" 1
    if ! link_is_active "$device"; then return 1; fi
  done
}
has_usable_ipv4() {
  local address; address="$($ipconfig_bin getifaddr "$1" 2>/dev/null || true)"
  [[ -n "$address" && "$address" != 169.254.* ]]
}
record_transition() {
  "$logger_bin" -t com.eisenhower.wifi-watchdog \
    "component=wifi-watchdog transition=$1" >/dev/null 2>&1 || true
}
ensure_service_and_radio() {
  local device="$1"
  if ! "$networksetup_bin" -getnetworkserviceenabled "$network_service" 2>/dev/null | grep -Fq Enabled; then
    record_transition service_disabled
    "$networksetup_bin" -setnetworkserviceenabled "$network_service" on >/dev/null 2>&1 || return 1
  fi
  if ! "$networksetup_bin" -getairportpower "$device" 2>/dev/null | grep -Fq ': On'; then
    record_transition radio_disabled
    "$networksetup_bin" -setairportpower "$device" on >/dev/null 2>&1 || return 1
  fi
}
associate_target() {
  local device="$1"
  if ! "$networksetup_bin" -setairportnetwork "$device" "$target_ssid" >/dev/null 2>&1; then
    last_state=authentication_failed; return 1
  fi
  last_asserted_at="$(date +%s)"
  for _ in {1..15}; do
    if link_is_active "$device" && has_usable_ipv4 "$device"; then last_state=healthy; return 0; fi
    "$sleep_bin" 1
  done
  last_state=associated_no_address; return 1
}
check_once() {
  local device now; device="$(wifi_device)"
  if [[ -z "$device" ]]; then last_state=interface_missing; return 1; fi
  if ! target_is_preferred "$device"; then last_state=credential_unavailable; return 1; fi
  if ! ensure_service_and_radio "$device"; then last_state=command_failed; return 1; fi
  now="$(date +%s)"
  if link_is_active "$device" && has_usable_ipv4 "$device" &&
      (( now - last_asserted_at < reassert_interval )); then last_state=healthy; return 0; fi
  associate_target "$device"
}
case "${1:-}" in
  --print-backoff) backoff_for "${2:?failure count required}"; exit 0;;
  --wait-healthy) wait_healthy_interval "${2:?device required}"; exit $?;;
  --once)
    if check_once; then write_status "$last_state" 0 0; exit 0; fi
    write_status "$last_state" 1 "$(backoff_for 1)"; exit 1;;
  "");;
  *) exit 64;;
esac
failures=0
while true; do
  if check_once; then
    failures=0
    write_status healthy 0 "$healthy_interval"
    if ! wait_healthy_interval "$(wifi_device)"; then continue; fi
  else
    failures=$((failures + 1)); delay="$(backoff_for "$failures")"
    write_status "$last_state" "$failures" "$delay"; "$sleep_bin" "$delay"
  fi
done
```

- [ ] **Step 4: Run tests and ShellCheck, then commit**

```bash
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
nix shell nixpkgs#shellcheck --command shellcheck \
  hosts/eisenhower/wifi-watchdog.sh hosts/eisenhower/tests/wifi-watchdog-test.sh
git add hosts/eisenhower/wifi-watchdog.sh hosts/eisenhower/tests/wifi-watchdog-test.sh
git diff --cached --check
git commit -m "feat(eisenhower): add Wi-Fi reconnect watchdog"
```

Expected: test `PASS`, ShellCheck exit 0, and no credential path staged.

### Task 5: Package the watchdog and declare launchd ownership

**Files:** Create `hosts/eisenhower/wifi-watchdog.nix`; modify Eisenhower assembly and evaluation test.

- [ ] **Step 1: Add failing launchd assertions**

```bash
wifi_job="$(nix eval --json .#darwinConfigurations.eisenhower.config.launchd.daemons.eisenhower-wifi-watchdog.serviceConfig)"
jq -e '.Label == "com.eisenhower.wifi-watchdog"' <<<"$wifi_job" >/dev/null
jq -e '.RunAtLoad == true and .KeepAlive == true and .ThrottleInterval == 30' <<<"$wifi_job" >/dev/null
jq -e '.ProgramArguments | length == 1' <<<"$wifi_job" >/dev/null
jq -e '.ProgramArguments[0] | endswith("/bin/eisenhower-wifi-watchdog")' <<<"$wifi_job" >/dev/null
jq -e 'has("EnvironmentVariables") | not' <<<"$wifi_job" >/dev/null
! grep -Eqi 'password|find-generic-password' <<<"$wifi_job"
```

Run `bash hosts/eisenhower/tests/eval-test.sh`. Expected: missing-daemon failure.

- [ ] **Step 2: Create `hosts/eisenhower/wifi-watchdog.nix`**

```nix
{ pkgs, ... }:
let
  watchdog = pkgs.writeShellApplication {
    name = "eisenhower-wifi-watchdog";
    runtimeInputs = with pkgs; [ coreutils gawk gnugrep gnused ];
    text = builtins.readFile ./wifi-watchdog.sh;
  };
in
{
  environment.systemPackages = [ watchdog ];
  launchd.daemons.eisenhower-wifi-watchdog.serviceConfig = {
    Label = "com.eisenhower.wifi-watchdog";
    ProgramArguments = [ "${watchdog}/bin/eisenhower-wifi-watchdog" ];
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Background";
    ThrottleInterval = 30;
    StandardOutPath = "/var/log/eisenhower-wifi-watchdog.log";
    StandardErrorPath = "/var/log/eisenhower-wifi-watchdog.error.log";
  };
}
```

- [ ] **Step 3: Import, test, and commit**

Add `./wifi-watchdog.nix` only to Eisenhower, then run:

```bash
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
bash hosts/eisenhower/tests/eval-test.sh
git add hosts/eisenhower/default.nix hosts/eisenhower/wifi-watchdog.nix hosts/eisenhower/tests/eval-test.sh
git diff --cached --check
git commit -m "feat(eisenhower): manage reconnect watchdog with launchd"
```

Expected: both tests `PASS`.

### Task 6: Complete static safety checks and documentation

**Files:** Modify `README.md`; verify all Eisenhower files.

- [ ] **Step 1: Prove repository boundaries**

```bash
shasum -a 256 -c /tmp/eisenhower-protected-files.sha256
sed -n '/darwinConfigurations\."turing"/,/^    };/p' flake.nix |
  shasum -a 256 -c /tmp/eisenhower-turing-flake-output.sha256
test "$(git -C /Users/melbournebaldove/nix-infra rev-parse HEAD)" = \
  "$(cat /tmp/eisenhower-nix-infra-head)"
test "$(git -C /Users/melbournebaldove/nix-infra status --porcelain=v1)" = \
  "$(cat /tmp/eisenhower-nix-infra-status.txt)"
```

Expected: all protected files report `OK`; the Turing output and `nix-infra` revision and worktree are unchanged.

- [ ] **Step 2: Prove the credential boundary**

```bash
! rg -n -i \
  'find-generic-password|dump-keychain|password[[:space:]]*=|security[[:space:]]+find' \
  hosts/eisenhower/wifi-watchdog.sh hosts/eisenhower/*.nix
test "$(rg -n -- '-setairportnetwork.*target_ssid' hosts/eisenhower/wifi-watchdog.sh | wc -l | tr -d ' ')" = 1
actual_ssid="$(sed -n "s/^readonly target_ssid='\\(.*\\)'$/\\1/p" \
  hosts/eisenhower/wifi-watchdog.sh)"
test "$(printf '%s' "$actual_ssid" | shasum -a 256 | awk '{print $1}')" = \
  8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
wifi_job="$(nix eval --json \
  .#darwinConfigurations.eisenhower.config.launchd.daemons.eisenhower-wifi-watchdog.serviceConfig)"
watchdog_program="$(jq -r '.ProgramArguments[0]' <<<"$wifi_job")"
watchdog_store="${watchdog_program%/bin/*}"
nix-store -r "$watchdog_store" >/dev/null
test -x "$watchdog_program"
! rg -n -i 'find-generic-password|dump-keychain|password[[:space:]]*=' \
  "$watchdog_program"
```

Expected: no prohibited pattern, one association call, the fixed SSID hash, the packaged Nix store script, and all watchdog tests pass. The launchd job has no credential environment.

- [ ] **Step 3: Evaluate and build without activation**

```bash
bash hosts/eisenhower/tests/eval-test.sh
nix build .#darwinConfigurations.eisenhower.system --no-link
test "$(nix eval --raw .#darwinConfigurations.turing.config.networking.hostName)" = turing
```

Expected: all commands exit 0.

- [ ] **Step 4: Document both independent Darwin commands**

Add this host table and keep the existing Turing command:

```markdown
## Hosts

| Host | Flake output | Role |
|---|---|---|
| Turing | `turing` | Personal interactive macOS workstation |
| Eisenhower | `eisenhower` | Personal macOS host for always-on Aura services |

sudo darwin-rebuild switch --flake .#eisenhower
```

- [ ] **Step 5: Commit only README**

```bash
git add README.md
git diff --cached --check
git commit -m "docs: add Eisenhower activation command"
```

### Task 7: Preflight the native credential and safe management path

**Files:** No repository changes; inspect live Eisenhower.

- [ ] **Step 1: Require host reachability and a route independent of Wi-Fi**

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=1 \
  eisenhower.local 'hostname'
```

Expected: the host returns `eisenhower`. The current known condition is name-resolution failure. Stop all live steps while this command fails. After reachability returns, test physical console, Ethernet, or another route that remains usable when Wi-Fi is off. Stop if Wi-Fi SSH is the only route.

- [ ] **Step 2: Verify the preferred identity without printing other networks**

```bash
iface="$(/usr/sbin/networksetup -listallhardwareports |
  awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}')"
test -n "$iface"
/usr/sbin/networksetup -listpreferredwirelessnetworks "$iface" 2>/dev/null |
  sed '1d; s/^[[:space:]]*//' |
  grep -Fqx -- 'Schrödinger’s WiFi'
echo "preferred target: PASS"
```

Expected: `preferred target: PASS`; no list output.

- [ ] **Step 3: Prove association with no password argument**

```bash
test "$(/usr/sbin/networksetup -help 2>&1 |
  grep -F 'Usage: networksetup -setairportnetwork <device name> <network> [password]' |
  wc -l | tr -d ' ')" = 1
sudo /usr/sbin/networksetup -setairportnetwork "$iface" 'Schrödinger’s WiFi'
```

Expected: exit 0 without a prompt. If it fails, stop and provision the network interactively through System Settings. Never inspect the Keychain.

- [ ] **Step 4: Define the timed failsafe for each fault test**

```bash
arm_wifi_failsafe() {
  sudo -v
  sudo nohup /bin/sh -c '
    sleep 180
    /sbin/ifconfig "$1" up
    /usr/sbin/networksetup -setnetworkserviceenabled "Wi-Fi" on
    /usr/sbin/networksetup -setairportpower "$1" on
  ' sh "$iface" >/var/tmp/eisenhower-wifi-failsafe.log 2>&1 &
}
```

Expected: calling `arm_wifi_failsafe` starts a root process that restores the interface, service, and radio after three minutes. Call it immediately before each disruptive local fault. One call does not protect later tests.

### Task 8: Create a known first Darwin generation

**Files:** No repository changes; activate only the host-only Task 2 commit on Eisenhower.

- [ ] **Step 1: Resolve and inspect the host-only baseline**

```bash
baseline_commit="$(git log --format=%H --grep='^feat(darwin): add Eisenhower host assembly$' -1)"
test -n "$baseline_commit"
test "$(git show -s --format=%s "$baseline_commit")" = \
  'feat(darwin): add Eisenhower host assembly'
test -z "$(git ls-tree -r --name-only "$baseline_commit" |
  grep -E '^hosts/eisenhower/(power\.nix|wifi-watchdog)')"
baseline_parent="$(mktemp -d /var/tmp/eisenhower-host-baseline.XXXXXX)"
baseline_dir="$baseline_parent/worktree"
git worktree add --detach "$baseline_dir" "$baseline_commit"
printf '%s\n' "$baseline_dir" > /var/tmp/eisenhower-host-baseline-worktree
```

Expected: the detached worktree contains the Eisenhower host assembly but no new power or Wi-Fi control. Keep this worktree until rollback proof is complete.

- [ ] **Step 2: Check and build the baseline**

```bash
nix_darwin_rev="$(nix flake metadata --json |
  jq -r '.locks.nodes[.locks.nodes.root.inputs["nix-darwin"]].locked.rev')"
nix_bin="$(command -v nix)"
test -x "$nix_bin"
darwin_rebuild=("$nix_bin" run "github:nix-darwin/nix-darwin/${nix_darwin_rev}#darwin-rebuild" --)
sudo "${darwin_rebuild[@]}" check --flake "$baseline_dir#eisenhower"
sudo "${darwin_rebuild[@]}" build --flake "$baseline_dir#eisenhower"
```

Expected: both commands exit 0. Stop on unsafe-overwrite or Home Manager collision errors.

- [ ] **Step 3: Activate the known baseline from the independent route**

```bash
sudo "${darwin_rebuild[@]}" switch --flake "$baseline_dir#eisenhower"
"${darwin_rebuild[@]}" --list-generations > /var/tmp/eisenhower-generations-baseline.txt
test -s /var/tmp/eisenhower-generations-baseline.txt
readlink /nix/var/nix/profiles/system > /var/tmp/eisenhower-baseline-system-path
test -s /var/tmp/eisenhower-baseline-system-path
```

Expected: Eisenhower has one known nix-darwin generation and its exact system profile path is recorded. The former sleep jobs remain loaded. Native macOS Wi-Fi behavior remains in use. If `darwin-rebuild` was absent before this step, use the pinned `nix run` command as shown.

### Task 9: Check, build, and activate the complete Eisenhower configuration

**Files:** No new repository changes; activate `.dotfiles#eisenhower` locally.

- [ ] **Step 1: Record generations and old-job evidence**

```bash
darwin-rebuild --list-generations > /var/tmp/eisenhower-generations-before.txt
sudo launchctl print system/com.local.nosleep > /var/tmp/com.local.nosleep.before.txt 2>&1 || true
sudo launchctl print system/com.aura.caffeinate > /var/tmp/com.aura.caffeinate.before.txt 2>&1 || true
```

- [ ] **Step 2: Check and build before switch**

```bash
sudo darwin-rebuild check --flake .#eisenhower
sudo darwin-rebuild build --flake .#eisenhower
```

Expected: both exit 0. Stop on unsafe-overwrite or Home Manager collision errors.

- [ ] **Step 3: Activate from the independent route**

First verify that `/var/tmp/eisenhower-generations-baseline.txt` and `/var/tmp/eisenhower-baseline-system-path` are not empty.

```bash
test -s /var/tmp/eisenhower-generations-baseline.txt
test -s /var/tmp/eisenhower-baseline-system-path
sudo darwin-rebuild switch --flake .#eisenhower
darwin-rebuild --list-generations > /var/tmp/eisenhower-generations-complete.txt
test "$(darwin-rebuild --list-generations | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')" -ge 2
test "$(readlink /nix/var/nix/profiles/system)" != \
  "$(cat /var/tmp/eisenhower-baseline-system-path)"
```

Expected: exit 0. Keep both old sleep jobs during this stage.

- [ ] **Step 4: Verify immediate state**

```bash
sudo launchctl print system/com.eisenhower.prevent-idle-sleep
sudo launchctl print system/com.eisenhower.wifi-watchdog
pmset -g custom
pmset -g assertions | grep -E 'Prevent(UserIdle)?SystemSleep|com.eisenhower'
sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
```

Expected: both jobs loaded, sleep disabled for AC and battery, assertion active, watchdog `healthy`. Do not rely on an unverified pre-nix-darwin system as a rollback target.

### Task 10: Verify reboot and recovery behavior

**Files:** No repository changes; live verification only.

- [ ] **Step 1: Reboot under local supervision**

```bash
sudo shutdown -r now
```

Expected after boot: independent route returns, both jobs load before login, watchdog reaches `healthy`.

- [ ] **Step 2: Observe no idle sleep on AC and battery**

```bash
pmset -g custom
pmset -g assertions
pmset -g log | tail -100
```

Expected on each power source: `sleep 0`, managed assertion, no idle system-sleep event during the agreed interval.

- [ ] **Step 3: Verify launchd restarts both assertion daemons**

```bash
sleep_pid="$(sudo launchctl print system/com.eisenhower.prevent-idle-sleep |
  awk '/pid =/{print $3; exit}')"
sudo kill "$sleep_pid"
sleep 15
sleep_pid_after="$(sudo launchctl print system/com.eisenhower.prevent-idle-sleep |
  awk '/pid =/{print $3; exit}')"
test -n "$sleep_pid_after"
test "$sleep_pid_after" != "$sleep_pid"
pmset -g assertions | grep -E 'Prevent(UserIdle)?SystemSleep|caffeinate'

pid="$(sudo launchctl print system/com.eisenhower.wifi-watchdog | awk '/pid =/{print $3; exit}')"
sudo kill "$pid"
sleep 35
pid_after="$(sudo launchctl print system/com.eisenhower.wifi-watchdog |
  awk '/pid =/{print $3; exit}')"
test -n "$pid_after"
test "$pid_after" != "$pid"
sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
```

Expected: each job has a new PID. The power assertion returns. The watchdog completes an immediate check and returns to `healthy`.

- [ ] **Step 4: Verify radio and service recovery with failsafe active**

```bash
arm_wifi_failsafe
sudo /usr/sbin/networksetup -setairportpower "$iface" off
sleep 40
/usr/sbin/networksetup -getairportpower "$iface"
arm_wifi_failsafe
sudo /usr/sbin/networksetup -setnetworkserviceenabled 'Wi-Fi' off
sleep 40
/usr/sbin/networksetup -getnetworkserviceenabled 'Wi-Fi'
sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
```

Expected: radio `On`, service `Enabled`, watchdog `healthy`.

- [ ] **Step 5: Verify forced disassociation**

From the target access point, disconnect only Eisenhower. Do not change or remove the preferred credential. Keep the independent management route active.

```bash
log stream --style compact \
  --predicate 'eventMessage CONTAINS "component=wifi-watchdog"'
```

Expected: an association attempt starts within five seconds. The watchdog returns to `healthy`, and its failure counter resets to zero. Confirm the exact target in local System Settings or in the target access point client view. Do not list other networks.

- [ ] **Step 6: Verify access-point outage and bounded backoff**

Obtain explicit approval for the outage window. Turn off the target access point externally, then observe sanitized events only:

```bash
log stream --style compact --predicate 'eventMessage CONTAINS "component=wifi-watchdog"'
```

Expected delays: `5, 10, 20, 40, 60, 120, 300, 300`. Restore the access point. Expected recovery within 300 seconds plus association time.

- [ ] **Step 7: Audit live credential safety**

```bash
ps axww -o pid=,command= | grep -F eisenhower-wifi-watchdog | grep -v grep
if sudo grep -R -n -E 'password|find-generic-password|dump-keychain' \
  /var/db/eisenhower \
  /var/log/eisenhower-wifi-watchdog.log \
  /var/log/eisenhower-wifi-watchdog.error.log 2>/dev/null; then
  exit 1
fi
unexpected_state_files="$(sudo /bin/ls -1A /var/db/eisenhower |
  grep -Fvx 'wifi-watchdog.status' || true)"
test -z "$unexpected_state_files"
```

Expected: no password argument, Keychain command, password log, or service credential file. The service-state directory contains only the sanitized watchdog status file. Never search for the password value.

### Task 11: Retire old sleep jobs only after proof

**Files:** No repository changes; move live unmanaged files to a recoverable location.

- [ ] **Step 1: Require complete evidence**

Required: check/build, reboot, AC and battery observation, launchd restart, radio/service recovery, credential audit, and access-point outage and recovery. The user can defer the outage test, but the old sleep jobs then remain in place.

- [ ] **Step 2: Move rather than delete the old jobs**

With explicit approval:

```bash
backup_dir="/Library/LaunchDaemons.disabled/eisenhower-$(date +%Y%m%d-%H%M%S)"
sudo mkdir -p "$backup_dir"
sudo launchctl bootout system /Library/LaunchDaemons/com.local.nosleep.plist 2>/dev/null || true
sudo launchctl bootout system /Library/LaunchDaemons/com.aura.caffeinate.plist 2>/dev/null || true
sudo mv /Library/LaunchDaemons/com.local.nosleep.plist "$backup_dir/"
sudo mv /Library/LaunchDaemons/com.aura.caffeinate.plist "$backup_dir/"
printf '%s\n' "$backup_dir" | sudo tee /var/db/eisenhower/retired-sleep-jobs-path >/dev/null
```

Expected: both property lists preserved; nothing deleted.

- [ ] **Step 3: Re-run power checks**

```bash
sudo launchctl print system/com.eisenhower.prevent-idle-sleep
pmset -g custom
pmset -g assertions
```

Expected: new controls remain effective without old jobs.

### Task 12: Exercise rollback and restoration

**Files:** No repository changes; live generation rollback.

- [ ] **Step 1: Roll back from the independent route**

```bash
test "$(darwin-rebuild --list-generations | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')" -ge 2
sudo darwin-rebuild switch --rollback
test "$(readlink /nix/var/nix/profiles/system)" = \
  "$(cat /var/tmp/eisenhower-baseline-system-path)"
sudo /usr/sbin/networksetup -setnetworkserviceenabled 'Wi-Fi' on
sudo /sbin/ifconfig "$iface" up
sudo /usr/sbin/networksetup -setairportpower "$iface" on
if sudo launchctl print system/com.eisenhower.wifi-watchdog >/dev/null 2>&1; then
  exit 1
fi
```

Expected: the known host-only Task 2 generation is active, the new watchdog is unloaded, and native radio and service controls are on. Do not use rollback if generation history does not contain both the baseline and complete configurations.

- [ ] **Step 2: Restore old jobs if retired**

```bash
backup_dir="$(sudo cat /var/db/eisenhower/retired-sleep-jobs-path 2>/dev/null || true)"
if [[ -n "$backup_dir" ]]; then
  sudo mv "$backup_dir/com.local.nosleep.plist" /Library/LaunchDaemons/
  sudo mv "$backup_dir/com.aura.caffeinate.plist" /Library/LaunchDaemons/
  sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.nosleep.plist
  sudo launchctl bootstrap system /Library/LaunchDaemons/com.aura.caffeinate.plist
fi
```

Expected: former sleep controls restored; no credential changes.

- [ ] **Step 3: Re-activate the proven generation**

```bash
sudo darwin-rebuild switch --flake .#eisenhower
```

Expected: managed jobs return and reach healthy state.

- [ ] **Step 4: Remove the detached baseline worktree after rollback proof**

```bash
baseline_dir="$(cat /var/tmp/eisenhower-host-baseline-worktree)"
baseline_parent="$(dirname "$baseline_dir")"
git worktree remove "$baseline_dir"
rmdir "$baseline_parent"
```

Expected: only the temporary detached worktree is removed. No repository file or Darwin generation is removed.

## Plan self-review

### Critical gates

- Stop before activation if password-free native association fails. Correction is interactive System Settings provisioning only.
- Stop all live steps while Eisenhower is unreachable. Host unreachability does not block local evaluation or design validation.
- Stop reboot and Wi-Fi fault tests unless an independent management route works.
- Create and verify the host-only first Darwin generation before the complete configuration. Do not assume that a pre-nix-darwin installation can roll back.
- Exclude all three protected files from every commit. Keep their recorded hashes valid. Keep the Turing flake output hash valid.

### Important gaps and controls

- `networksetup` has no stable structured reason for all association failures. Use the conservative sanitized `authentication_failed` state; recovery does not depend on finer classification.
- Command-line status redacts the active SSID. Proof combines exact preferred identity, password-free association success, link/address health, and local System Settings or access-point evidence.
- A full healthy-state check runs every 30 seconds. A one-second link-state sentinel starts the next association cycle within five seconds after forced disassociation.
- Reusing the GUI and Home Manager profiles can change user state. Build/check and local first activation are mandatory. Do not import the Darwin agenix or WireGuard system modules. The shared `dev.nix` profile continues to provide its existing agenix and WireGuard command-line packages, but it declares no Eisenhower credential.
- The access-point outage affects other people and needs an approved window.
- Arm a new timed failsafe immediately before each local Wi-Fi fault. A failsafe from an earlier step can expire.
- Old sleep jobs remain until all proof, including access-point recovery, passes. They are moved to a recoverable directory, not deleted.

### Coverage

- Host isolation: Tasks 1, 2, and 6.
- Sleep prevention: Tasks 3, 9, 10, and 11.
- Password-free reconnect and backoff: Tasks 4, 5, 7, and 10.
- Observability and secret safety: Tasks 4, 6, 9, and 10.
- First-generation safety and rollback: Tasks 8, 9, and 12.
- Reboot, fault recovery, and safe cutover: Tasks 7 through 11.

After this review is clean, local implementation starts in a separate SOL-medium turn. Live activation remains subject to Tasks 7 and 8.
