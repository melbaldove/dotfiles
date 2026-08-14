# Eisenhower Native-First Wi-Fi Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the competing direct Wi-Fi association request and make Eisenhower create bounded recovery opportunities for native macOS Auto-Join.

**Architecture:** Native macOS Auto-Join is the only association owner. The root watchdog validates the approved home-network contract, restores a disabled Wi-Fi service or radio, waits for native recovery, and uses one bounded radio cycle when recovery stalls. A watchdog-disabled nix-darwin closure is the live rollback target.

**Tech Stack:** Nix flakes, nix-darwin, launchd, Bash, `networksetup`, `ifconfig`, `ipconfig`, `route`, `dscacheutil`, `curl`, `nc`, and the macOS unified log.

---

## Locked constraints

- Work only in `/Users/melbournebaldove/.dotfiles`.
- Do not modify `/Users/melbournebaldove/nix-infra`.
- Preserve `darwinConfigurations.turing`, `hosts/turing/default.nix`, and all unrelated worktree changes byte-for-byte.
- Use the exact UTF-8 SSID `Schrödinger’s WiFi` and SHA-256 `8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d`.
- Never read, extract, pass, store, or log the Wi-Fi password.
- Never invoke `networksetup -setairportnetwork` or a private Wi-Fi association API.
- Do not change the power policy, Home Manager, Homebrew, Aura, host assembly, or launchd job definition.
- Build and review both rollback and corrected closures before activation.
- Do not activate, reboot, or disrupt Wi-Fi until the local-console and timed-failsafe gates pass.
- Keep router or access-point changes in a separate approved outage window.

## Source-grounded defect

The active `hosts/eisenhower/wifi-watchdog.sh` calls `networksetup -setairportnetwork` as soon as its strict health contract fails. During the 2026-08-14 incident, native Auto-Join started at `06:41:52`; the watchdog started a competing join at `06:42:04`; macOS then disabled Auto-Join during the join, returned internal failure `-3900`, disassociated, and blocklisted the known network. The watchdog failed 203 times until a manual selection recovered the host.

Controlled tests on 2026-08-15 paused the watchdog and cycled the radio. Native Auto-Join recovered the approved address, gateway, DNS, HTTPS, and SSH contract in five seconds while the screen was unlocked and while it was locked. The correction must remove the competing join and correct the earlier synthetic verification that made a fake association command create a healthy route.

## File map

- Modify `hosts/eisenhower/wifi-watchdog.sh`: implement native-first recovery and causal status.
- Modify `hosts/eisenhower/tests/wifi-watchdog-test.sh`: replace synthetic association recovery with explicit external state transitions and add regression coverage.
- Do not modify `hosts/eisenhower/wifi-watchdog.nix`: the existing package and system launch daemon remain correct.
- Do not modify `hosts/eisenhower/default.nix`, `hosts/eisenhower/power.nix`, `flake.nix`, or any Turing file.

### Task 1: Record protected local and live baselines

**Files:** Read repository state, current Darwin closures, and active services. Create evidence only under `/tmp` locally and `/var/db/eisenhower-cutover` on Eisenhower during the approved activation window.

- [ ] **Step 1: Record the local protected paths**

```bash
cd /Users/melbournebaldove/.dotfiles
git merge-base --is-ancestor 73bdb38 HEAD
git status --short --branch
shasum -a 256 \
  claude/settings.json \
  codex/AGENTS.md \
  flake.lock \
  hosts/turing/default.nix \
  flake.nix \
  hosts/eisenhower/default.nix \
  hosts/eisenhower/power.nix \
  hosts/eisenhower/wifi-watchdog.nix \
  > /tmp/eisenhower-native-first-protected.sha256
git -C /Users/melbournebaldove/nix-infra rev-parse HEAD \
  > /tmp/eisenhower-native-first-nix-infra-head
git -C /Users/melbournebaldove/nix-infra status --porcelain=v1 \
  > /tmp/eisenhower-native-first-nix-infra-status
```

Expected: the four known unrelated `.dotfiles` changes remain visible. The `nix-infra` status is unchanged from its current baseline. Stop if a new overlap exists in either watchdog file.

- [ ] **Step 2: Record the live read-only baseline**

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 192.168.50.140 '
  set -eu
  test "$(hostname)" = eisenhower
  readlink /run/current-system
  readlink /nix/var/nix/profiles/system
  sudo launchctl print system/com.eisenhower.wifi-watchdog |
    egrep "state =|pid =|runs =|last exit code"
  sudo launchctl print system/com.eisenhower.prevent-idle-sleep |
    egrep "state =|pid =|runs =|last exit code"
  sudo sed -n "1,20p" /var/db/eisenhower/wifi-watchdog.status
  pgrep -lf aura
'
```

Expected: host `eisenhower`, active nix-darwin system, both Eisenhower jobs, and Aura are present. This command does not change the host.

- [ ] **Step 3: Commit no files**

This task records evidence only. Do not stage or commit `/tmp` data.

### Task 2: Write the native-first failing regression tests

**Files:** Modify `hosts/eisenhower/tests/wifi-watchdog-test.sh`.

- [ ] **Step 1: Make direct association a hard test failure**

Replace the fake `-setairportnetwork)` branch with:

```bash
  -setairportnetwork)
    printf 'forbidden_direct_association %s\n' "$*" >>"$FAKE_CALLS"
    exit 70
    ;;
```

Delete `FAKE_ASSOC_ARGC`, `FAKE_ASSOC_ARGS`, `FAKE_ASSOC_RESULT`, and `FAKE_ASSOC_RECOVERS`. The fake association command must not create an address, gateway, route, or active link.

- [ ] **Step 2: Make service and radio state observable**

Use these exact fake branches:

```bash
  -getnetworkserviceenabled)
    cat "$FAKE_SERVICE_STATE_FILE"
    ;;
  -setnetworkserviceenabled)
    printf '%s\n' "$*" >>"$FAKE_CALLS"
    printf 'Enabled\n' >"$FAKE_SERVICE_STATE_FILE"
    ;;
  -getairportpower)
    printf 'Wi-Fi Power (%s): %s\n' "$2" "$(cat "$FAKE_RADIO_STATE_FILE")"
    ;;
  -setairportpower)
    printf '%s\n' "$*" >>"$FAKE_CALLS"
    case "$3" in
      on) printf 'On\n' >"$FAKE_RADIO_STATE_FILE" ;;
      off) printf 'Off\n' >"$FAKE_RADIO_STATE_FILE" ;;
      *) exit 64 ;;
    esac
    ;;
```

- [ ] **Step 3: Add an explicit external recovery fixture**

Replace the fake `sleep` script with:

```bash
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$1" >>"$FAKE_SLEEPS"
count="$(wc -l <"$FAKE_SLEEPS" | tr -d ' ')"
if [[ -n "${FAKE_RECOVER_AT_SLEEP_COUNT:-}" ]] &&
   (( count == FAKE_RECOVER_AT_SLEEP_COUNT )); then
  printf 'active\n' >"$FAKE_LINK_STATE_FILE"
  printf '192.168.50.140\n' >"$FAKE_IPV4_FILE"
  printf '192.168.50.1\n' >"$FAKE_GATEWAY_FILE"
  printf 'en7\n' >"$FAKE_ROUTE_INTERFACE_FILE"
fi
if [[ -n "${FAKE_SLEEP_LIMIT:-}" ]] && (( count >= FAKE_SLEEP_LIMIT )); then
  exit 99
fi
```

This fixture models macOS changing network state independently. No watchdog command manufactures recovery.

- [ ] **Step 4: Add exact native-first cases**

Initialize state files once:

```bash
service_state_file="$test_dir/service-state"
radio_state_file="$test_dir/radio-state"
link_state_file="$test_dir/link-state"
ipv4_state_file="$test_dir/ipv4-state"
gateway_state_file="$test_dir/gateway-state"
route_interface_state_file="$test_dir/route-interface-state"
export FAKE_SERVICE_STATE_FILE="$service_state_file"
export FAKE_RADIO_STATE_FILE="$radio_state_file"
export FAKE_LINK_STATE_FILE="$link_state_file"
export FAKE_IPV4_FILE="$ipv4_state_file"
export FAKE_GATEWAY_FILE="$gateway_state_file"
export FAKE_ROUTE_INTERFACE_FILE="$route_interface_state_file"
```

Replace `reset_case` with:

```bash
reset_case() {
  : >"$FAKE_CALLS"
  : >"$FAKE_LOG"
  : >"$FAKE_SLEEPS"
  : >"$FAKE_HEALTH_CALLS"
  rm -f "$EISENHOWER_STATUS_FILE"
  printf 'Enabled\n' >"$FAKE_SERVICE_STATE_FILE"
  printf 'On\n' >"$FAKE_RADIO_STATE_FILE"
  printf 'active\n' >"$FAKE_LINK_STATE_FILE"
  printf '192.168.50.140\n' >"$FAKE_IPV4_FILE"
  printf '192.168.50.1\n' >"$FAKE_GATEWAY_FILE"
  printf 'en7\n' >"$FAKE_ROUTE_INTERFACE_FILE"
  export FAKE_PREFERRED=yes FAKE_SERVICE_NAME='Primary Wireless'
  export FAKE_SERVICE_ORDER_DISABLED=no FAKE_NETMASK=0xffffff00
  export FAKE_DNS_STATE=ready FAKE_HTTPS_STATE=ready
  export FAKE_MANAGEMENT_STATE=ready
  unset FAKE_RECOVER_AT_SLEEP_COUNT FAKE_SLEEP_LIMIT
}
```

Add assertions for these cases:

```bash
# Healthy and idempotent: no recovery command.
bash "$watchdog" --once
test ! -s "$FAKE_CALLS"
grep -Fq 'state=healthy' "$EISENHOWER_STATUS_FILE"

# Link loss recovers during native grace.
reset_case
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
printf '198.51.100.140\n' >"$FAKE_IPV4_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=5
bash "$watchdog" --once
test ! -s "$FAKE_CALLS"
grep -Fq 'transition=native_autojoin_wait' "$FAKE_LOG"

# Disabled service is restored before native recovery.
reset_case
printf 'Disabled\n' >"$FAKE_SERVICE_STATE_FILE"
export FAKE_SERVICE_ORDER_DISABLED=yes
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=5
bash "$watchdog" --once
test "$(sed -n '1p' "$FAKE_CALLS")" = \
  '-setnetworkserviceenabled Primary Wireless on'
if grep -Fq forbidden_direct_association "$FAKE_CALLS"; then exit 1; fi

# Disabled radio is restored before native recovery.
reset_case
printf 'Off\n' >"$FAKE_RADIO_STATE_FILE"
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=5
bash "$watchdog" --once
grep -Fqx -- '-setairportpower en7 on' "$FAKE_CALLS"

# Stalled native recovery causes one radio cycle, then recovers.
reset_case
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=35
bash "$watchdog" --once
test "$(grep -Fc -- '-setairportpower en7 off' "$FAKE_CALLS")" = 1
test "$(grep -Fc -- '-setairportpower en7 on' "$FAKE_CALLS")" = 1
grep -Fq 'transition=radio_cycle' "$FAKE_LOG"

# A persistent address failure keeps its causal component.
reset_case
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
if bash "$watchdog" --once; then exit 1; fi
grep -Fq 'state=native_recovery_failed' "$EISENHOWER_STATUS_FILE"
grep -Fq 'failed_component=address' "$EISENHOWER_STATUS_FILE"

# Missing preferred target fails closed and logs no unrelated SSID.
reset_case
export FAKE_PREFERRED=no
if bash "$watchdog" --once; then exit 1; fi
test ! -s "$FAKE_CALLS"
grep -Fq 'state=preferred_target_unavailable' "$EISENHOWER_STATUS_FILE"
if grep -Fq 'Unrelated Network' "$FAKE_LOG"; then exit 1; fi

# DNS and HTTPS failures do not cycle the radio.
for online_failure in dns https; do
  reset_case
  if [[ "$online_failure" == dns ]]; then
    export FAKE_DNS_STATE=failed
  else
    export FAKE_HTTPS_STATE=failed
  fi
  if bash "$watchdog" --once; then exit 1; fi
  test ! -s "$FAKE_CALLS"
  grep -Fq "state=${online_failure}_failed" "$EISENHOWER_STATUS_FILE"
done

# The retry contract is exact.
expected=(60 120 300 300)
for index in "${!expected[@]}"; do
  test "$(bash "$watchdog" --print-backoff "$((index + 1))")" = \
    "${expected[$index]}"
done

# A healthy interval is one 30-second wait followed by a full-contract check.
reset_case
bash "$watchdog" --wait-healthy en7
test "$(paste -sd, "$FAKE_SLEEPS")" = 30

# Direct association and credential reads are forbidden.
if rg -n 'setairportnetwork|find-generic-password|password=' "$watchdog"; then
  exit 1
fi
```

Keep the existing wrong-address, subnet, gateway, route, redaction, failure-reset, and Unicode-hash assertions. A persistent network-identity failure ends as `native_recovery_failed`; its status keeps `failed_component=address`, `route`, or `management`. DNS-only and HTTPS-only failures end as `dns_failed` or `https_failed` without a radio cycle.

- [ ] **Step 5: Run the regression test and prove red**

```bash
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
```

Expected: FAIL because the current watchdog calls `networksetup -setairportnetwork`, uses the old backoff, and lacks native recovery transitions.

### Task 3: Implement the native-first watchdog

**Files:** Modify `hosts/eisenhower/wifi-watchdog.sh`.

- [ ] **Step 1: Replace retry constants and direct-association state**

Add:

```bash
readonly native_recovery_window=30
readonly radio_cycle_off_seconds=2
last_state=command_failed
last_trigger=none
last_component=command
```

Replace `backoff_for` with:

```bash
backoff_for() {
  case "$1" in
    1) echo 60 ;;
    2) echo 120 ;;
    *) echo 300 ;;
  esac
}
```

- [ ] **Step 2: Add causal status fields**

Replace `write_status` with:

```bash
write_status() {
  local state="$1" failures="$2" delay="$3" tmp
  umask 077
  mkdir -p "$(dirname "$status_file")"
  tmp="${status_file}.$$"
  printf 'state=%s\nfailures=%s\nnext_retry_seconds=%s\nrecovery_trigger=%s\nfailed_component=%s\nupdated_at=%s\n' \
    "$state" "$failures" "$delay" "$last_trigger" "$last_component" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$tmp"
  mv -f "$tmp" "$status_file"
  "$logger_bin" -t com.eisenhower.wifi-watchdog \
    "component=wifi-watchdog state=$state failures=$failures next_retry_seconds=$delay recovery_trigger=$last_trigger failed_component=$last_component" \
    >/dev/null 2>&1 || true
}

record_transition() {
  "$logger_bin" -t com.eisenhower.wifi-watchdog \
    "component=wifi-watchdog transition=$1" >/dev/null 2>&1 || true
}
```

- [ ] **Step 3: Separate network identity from online-service health**

Replace `network_contract_is_healthy` with:

```bash
network_identity_is_healthy() {
  local device="$1"
  if ! link_is_active "$device" || ! has_expected_ipv4_and_subnet "$device"; then
    last_state=address_failed
    last_component=address
    return 1
  fi
  if ! default_route_matches "$device"; then
    last_state=route_failed
    last_component=route
    return 1
  fi
  if ! management_is_reachable; then
    last_state=management_failed
    last_component=management
    return 1
  fi
  return 0
}

online_services_are_healthy() {
  if ! dns_works; then
    last_state=dns_failed
    last_component=dns
    return 1
  fi
  if ! https_works; then
    last_state=https_failed
    last_component=https
    return 1
  fi
  return 0
}

network_contract_is_healthy() {
  local device="$1"
  network_identity_is_healthy "$device" &&
    online_services_are_healthy
}
```

- [ ] **Step 4: Add supported service, radio, wait, and cycle operations**

Replace `ensure_service_and_radio` and delete `associate_target`. Add:

```bash
radio_is_on() {
  "$networksetup_bin" -getairportpower "$1" 2>/dev/null |
    grep -Fq ': On'
}

ensure_service_and_radio() {
  local device="$1" service service_ready
  service="$(wifi_service "$device")"
  if [[ -z "$service" ]]; then
    last_state=command_failed
    return 1
  fi
  if ! service_is_enabled "$service"; then
    record_transition service_disabled
    "$networksetup_bin" -setnetworkserviceenabled "$service" on \
      >/dev/null 2>&1 || return 1
    service_ready=false
    for _ in {1..5}; do
      if service_is_enabled "$service"; then
        service_ready=true
        break
      fi
      "$sleep_bin" 1
    done
    [[ "$service_ready" == true ]] || return 1
    last_trigger=service_restored
    record_transition service_restored
  fi
  if ! radio_is_on "$device"; then
    record_transition radio_disabled
    "$networksetup_bin" -setairportpower "$device" on \
      >/dev/null 2>&1 || return 1
    last_trigger=radio_restored
    record_transition radio_restored
  fi
}

wait_for_native_recovery() {
  local device="$1" second
  if [[ "$last_trigger" == none ]]; then
    last_trigger=native_autojoin_wait
  fi
  record_transition native_autojoin_wait
  for ((second = 1; second <= native_recovery_window; second++)); do
    "$sleep_bin" 1
    if network_identity_is_healthy "$device"; then
      return 0
    fi
  done
  return 1
}

cycle_radio() {
  local device="$1"
  last_trigger=radio_cycle
  record_transition radio_cycle
  "$networksetup_bin" -setairportpower "$device" off \
    >/dev/null 2>&1 || return 1
  "$sleep_bin" "$radio_cycle_off_seconds"
  "$networksetup_bin" -setairportpower "$device" on \
    >/dev/null 2>&1 || return 1
}
```

- [ ] **Step 5: Replace `check_once` with native-first control flow**

```bash
check_once() {
  local device
  last_trigger=none
  last_component=none
  device="$(wifi_device)"
  if [[ -z "$device" ]]; then
    last_state=interface_missing
    last_component=interface
    return 1
  fi
  if ! target_is_preferred "$device"; then
    last_state=preferred_target_unavailable
    last_component=preferred_target
    return 1
  fi
  if ! ensure_service_and_radio "$device"; then
    last_state=command_failed
    last_component=command
    return 1
  fi
  if network_identity_is_healthy "$device"; then
    if online_services_are_healthy; then
      last_state=healthy
      last_component=none
      return 0
    fi
    return 1
  fi
  if wait_for_native_recovery "$device"; then
    if online_services_are_healthy; then
      last_state=healthy
      last_component=none
      return 0
    fi
    return 1
  fi
  if ! cycle_radio "$device"; then
    last_state=command_failed
    last_component=command
    return 1
  fi
  if wait_for_native_recovery "$device"; then
    if online_services_are_healthy; then
      last_state=healthy
      last_component=none
      return 0
    fi
    return 1
  fi
  last_state=native_recovery_failed
  return 1
}
```

- [ ] **Step 6: Make the healthy interval a full-contract check**

Replace `wait_healthy_interval` with:

```bash
wait_healthy_interval() {
  local device="$1"
  "$sleep_bin" "$healthy_interval"
  network_contract_is_healthy "$device"
}
```

- [ ] **Step 7: Run the focused regression test and prove green**

```bash
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
```

Expected: `Wi-Fi watchdog tests: PASS`.

- [ ] **Step 8: Commit only the bounded local fix**

```bash
git add hosts/eisenhower/wifi-watchdog.sh \
  hosts/eisenhower/tests/wifi-watchdog-test.sh
git diff --cached --check
git diff --cached --name-only
git commit -m "fix(eisenhower): defer Wi-Fi recovery to Auto-Join"
```

Expected: the commit contains exactly the two watchdog files.

### Task 4: Run static, evaluation, and closure gates

**Files:** No new source files. Read the two watchdog files and evaluated Darwin output.

- [ ] **Step 1: Run the source and host tests**

```bash
cd /Users/melbournebaldove/.dotfiles
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
PROTECTED_BASELINE_FILE=/tmp/eisenhower-native-first-protected.sha256 \
  bash hosts/eisenhower/tests/eval-test.sh
git diff --check
```

Expected: both tests report `PASS`; protected hashes pass; diff check is silent.

- [ ] **Step 2: Prove forbidden behavior is absent**

```bash
if rg -n 'setairportnetwork|find-generic-password|security[[:space:]]+find-' \
  hosts/eisenhower/wifi-watchdog.sh; then
  exit 1
fi
printf '%s' 'Schrödinger’s WiFi' | shasum -a 256
```

Expected: the scan prints nothing. The hash is `8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d`.

- [ ] **Step 3: Run clean flake evaluation and build the corrected closure**

```bash
nix flake check --no-write-lock-file
corrected_system="$(nix build \
  .#darwinConfigurations.eisenhower.system \
  --no-link --print-out-paths)"
test -x "$corrected_system/activate"
test -f "$corrected_system/Library/LaunchDaemons/com.eisenhower.wifi-watchdog.plist"
printf '%s\n' "$corrected_system" > /tmp/eisenhower-native-first-corrected-system
```

Expected: flake check and build exit `0` without changing `flake.lock`.

- [ ] **Step 4: Scan the built package and closure**

```bash
watchdog_program="$(/usr/libexec/PlistBuddy -c \
  'Print :ProgramArguments:0' \
  "$corrected_system/Library/LaunchDaemons/com.eisenhower.wifi-watchdog.plist")"
test -x "$watchdog_program"
if rg -n 'setairportnetwork|find-generic-password|password=' \
  "$watchdog_program" \
  "$corrected_system/Library/LaunchDaemons/com.eisenhower.wifi-watchdog.plist"; then
  exit 1
fi
```

Expected: no forbidden association or credential operation appears.

- [ ] **Step 5: Recheck protected repositories and files**

```bash
shasum -a 256 -c /tmp/eisenhower-native-first-protected.sha256
test "$(git -C /Users/melbournebaldove/nix-infra rev-parse HEAD)" = \
  "$(cat /tmp/eisenhower-native-first-nix-infra-head)"
test "$(git -C /Users/melbournebaldove/nix-infra status --porcelain=v1)" = \
  "$(cat /tmp/eisenhower-native-first-nix-infra-status)"
git show --format= --name-only HEAD
```

Expected: all protected hashes pass. The implementation commit contains only the two watchdog files.

### Task 5: Obtain independent implementation review

**Files:** Review the implementation diff, approved specification, tests, and plan. Do not edit during the first review pass.

- [ ] **Step 1: Request a Critical/Important review**

Use `superpowers:requesting-code-review`. Review these risks explicitly:

- no direct association or credential access;
- native grace occurs before radio cycling;
- no radio cycle for DNS-only or HTTPS-only failure;
- disabled service and radio restoration order;
- exact `60, 120, 300` backoff;
- test fixtures do not manufacture health from a watchdog command;
- lock-screen and boot behavior are not inferred from unit tests;
- Turing, `nix-infra`, Aura, power policy, and unrelated work remain unchanged;
- rollback selects the watchdog-disabled closure, not the defective active closure.

- [ ] **Step 2: Fix only confirmed Critical or Important findings with TDD**

For each finding, add one failing regression, run it to prove red, apply the smallest correction, and rerun the focused suite. Commit the review fix separately:

```bash
git add hosts/eisenhower/wifi-watchdog.sh \
  hosts/eisenhower/tests/wifi-watchdog-test.sh
git diff --cached --check
git commit -m "fix(eisenhower): address native recovery review"
```

Skip this commit when the review has no Critical or Important finding.

- [ ] **Step 3: Repeat Task 4 after any review change**

Expected: all static, evaluation, closure, and protected-file gates pass from the reviewed commit.

### Task 6: Prepare live rollback and activation gates

**Files:** No repository changes. Create root-owned cutover metadata on Eisenhower only after the user approves the activation window and confirms physical local-console access.

- [ ] **Step 1: Require the local recovery route**

The operator must be at Eisenhower with the lid open, AC power connected, the graphical administrator session unlocked, and two Terminal windows open. SSH is secondary evidence only. Stop if this condition is not confirmed.

- [ ] **Step 2: Record the active and watchdog-disabled systems**

From the local console:

```bash
cutover_dir=/var/db/eisenhower-cutover/native-first
sudo mkdir -p "$cutover_dir"
sudo chmod 700 "$cutover_dir"
active_system="$(readlink /run/current-system)"
rollback_system=/nix/store/bdc2jicn6cc1jx97z5qyfw23lr3gnpjn-darwin-system-26.11.15abb8c
wifi_device="$(/usr/sbin/networksetup -listallhardwareports |
  awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}')"
wifi_service="$(/usr/sbin/networksetup -listnetworkserviceorder |
  awk -v device="$wifi_device" '
    /^\(([[:digit:]]+|\*)\) / {
      service = $0
      sub(/^\(([[:digit:]]+|\*)\) /, "", service)
      sub(/^\*/, "", service)
      next
    }
    index($0, "Device: " device ")") { print service; exit }
  ')"
test -x "$active_system/activate"
test -x "$rollback_system/activate"
test ! -e "$rollback_system/Library/LaunchDaemons/com.eisenhower.wifi-watchdog.plist"
test -n "$wifi_device"
test -n "$wifi_service"
printf '%s\n' "$active_system" | sudo tee "$cutover_dir/active-system" >/dev/null
printf '%s\n' "$rollback_system" | sudo tee "$cutover_dir/rollback-system" >/dev/null
printf '%s\n' "$wifi_device" | sudo tee "$cutover_dir/wifi-device" >/dev/null
printf '%s\n' "$wifi_service" | sudo tee "$cutover_dir/wifi-service" >/dev/null
```

Expected: the rollback closure exists and has no Eisenhower watchdog. Stop and rebuild the reviewed watchdog-disabled baseline if this exact store path is unavailable.

If the recorded store path is unavailable, rebuild the reviewed host-only commit without changing the live repository:

```bash
baseline_parent="$(mktemp -d /var/tmp/eisenhower-native-first-baseline.XXXXXX)"
baseline_dir="$baseline_parent/worktree"
git -C /Users/melbournebaldove/.dotfiles worktree add --detach \
  "$baseline_dir" 5e77663ce59cae384da0afd3d3262c4b07c78085
rollback_system="$(nix build \
  "$baseline_dir#darwinConfigurations.eisenhower.system" \
  --no-link --print-out-paths)"
test -x "$rollback_system/activate"
test ! -e "$rollback_system/Library/LaunchDaemons/com.eisenhower.wifi-watchdog.plist"
printf '%s\n' "$rollback_system" |
  sudo tee "$cutover_dir/rollback-system" >/dev/null
```

Expected: the rebuilt rollback system contains the Eisenhower host assembly but no Eisenhower power or Wi-Fi watchdog job.

- [ ] **Step 3: Transfer and verify the exact implementation commit**

On the operator Mac, create a bundle from committed history only:

```bash
cd /Users/melbournebaldove/.dotfiles
implementation_commit="$(git rev-parse HEAD)"
stage="$(mktemp -d /var/tmp/eisenhower-native-first-bundle.XXXXXX)"
git clone --bare . "$stage/repo.git"
git --git-dir="$stage/repo.git" update-ref \
  refs/heads/eisenhower-native-first "$implementation_commit"
git --git-dir="$stage/repo.git" bundle create \
  "$stage/eisenhower-native-first.bundle" \
  refs/heads/eisenhower-native-first
git bundle verify "$stage/eisenhower-native-first.bundle"
git bundle list-heads "$stage/eisenhower-native-first.bundle"
shasum -a 256 "$stage/eisenhower-native-first.bundle"
scp "$stage/eisenhower-native-first.bundle" \
  melbournebaldove@192.168.50.140:/var/tmp/
```

Expected: the bundle advertises one head at the exact reviewed implementation commit. Uncommitted local files are absent.

On Eisenhower, verify and fetch without merging:

```bash
cd /Users/melbournebaldove/.dotfiles
test -z "$(git status --porcelain=v1)"
git bundle verify /var/tmp/eisenhower-native-first.bundle
implementation_commit="$(git bundle list-heads \
  /var/tmp/eisenhower-native-first.bundle |
  awk '$2 == "refs/heads/eisenhower-native-first" {print $1}')"
test -n "$implementation_commit"
git fetch /var/tmp/eisenhower-native-first.bundle \
  refs/heads/eisenhower-native-first:refs/remotes/bundle/eisenhower-native-first
git switch --detach "$implementation_commit"
test "$(git rev-parse HEAD)" = "$implementation_commit"
test -z "$(git status --porcelain=v1)"
git fsck --full
```

Then run the exact source gates:

```bash
bash /Users/melbournebaldove/.dotfiles/hosts/eisenhower/tests/wifi-watchdog-test.sh
PROTECTED_BASELINE_FILE=/var/empty/eisenhower-no-baseline \
  bash /Users/melbournebaldove/.dotfiles/hosts/eisenhower/tests/eval-test.sh
```

Expected: the exact reviewed commit is checked out in a clean live repository and both tests pass.

- [ ] **Step 4: Build and compare live closures**

```bash
cd /Users/melbournebaldove/.dotfiles
corrected_system="$(nix build \
  .#darwinConfigurations.eisenhower.system \
  --no-link --print-out-paths)"
rollback_system="$(sudo cat /var/db/eisenhower-cutover/native-first/rollback-system)"
nix store diff-closures "$rollback_system" "$corrected_system"
printf '%s\n' "$corrected_system" |
  sudo tee /var/db/eisenhower-cutover/native-first/corrected-system >/dev/null
```

Expected: the closure difference contains the existing Eisenhower power controls and corrected watchdog. It contains no SSH, Nix ownership, Homebrew, Home Manager, Turing, Aura, credential, or unrelated configuration change.

- [ ] **Step 5: Create the timed rollback without association commands**

From the first local Terminal:

```bash
sudo /bin/sh -c '
  sleep 900
  rollback_system="$(cat /var/db/eisenhower-cutover/native-first/rollback-system)"
  wifi_device="$(cat /var/db/eisenhower-cutover/native-first/wifi-device)"
  wifi_service="$(cat /var/db/eisenhower-cutover/native-first/wifi-service)"
  case "$rollback_system" in /nix/store/*-darwin-system-*) ;; *) exit 1 ;; esac
  case "$wifi_device" in en[0-9]*) ;; *) exit 1 ;; esac
  test -n "$wifi_service"
  /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --set "$rollback_system"
  "$rollback_system/activate"
  /usr/sbin/networksetup -setnetworkserviceenabled "$wifi_service" on
  /usr/sbin/networksetup -setairportpower "$wifi_device" on
' >/var/tmp/eisenhower-native-first-failsafe.log 2>&1 &
failsafe_pid=$!
printf '%s\n' "$failsafe_pid" |
  sudo tee /var/db/eisenhower-cutover/native-first/failsafe.pid >/dev/null
sudo kill -0 "$failsafe_pid"
```

Expected: the failsafe is alive. It has no SSID or password argument. Do not disarm it until local health, services, Aura, and rollback readiness pass.

### Task 7: Activate the corrected healthy-link generation

**Files:** No repository changes. This task changes the active Darwin generation but does not intentionally disconnect Wi-Fi.

- [ ] **Step 1: Run the reviewed activation check locally**

```bash
cd /Users/melbournebaldove/.dotfiles
sudo /run/current-system/sw/bin/darwin-rebuild check --flake .#eisenhower
```

Expected: exit `0`. Stop on any unrelated activation effect.

- [ ] **Step 2: Activate the exact corrected closure**

```bash
corrected_system="$(sudo cat /var/db/eisenhower-cutover/native-first/corrected-system)"
test -x "$corrected_system/activate"
sudo /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --set "$corrected_system"
sudo "$corrected_system/activate"
```

Expected: activation succeeds. Because the home-network contract is already healthy, the new watchdog performs no service, radio, or association action.

- [ ] **Step 3: Verify non-disruptive live state**

```bash
test "$(hostname)" = eisenhower
wifi_device="$(sudo cat /var/db/eisenhower-cutover/native-first/wifi-device)"
sudo launchctl print system/com.eisenhower.wifi-watchdog
sudo launchctl print system/com.eisenhower.prevent-idle-sleep
sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
pmset -g custom
pmset -g assertions
/usr/sbin/ipconfig getifaddr "$wifi_device"
route -n get default
dscacheutil -q host -a name cache.nixos.org
curl -fsS --max-time 10 https://cache.nixos.org/nix-cache-info >/dev/null
pgrep -lf aura
```

Expected: `healthy`, zero failures, no recovery trigger, expected IP and gateway, DNS and HTTPS pass, both managed jobs run, sleep prevention is active, and Aura remains active.

- [ ] **Step 4: Prove the active process has no direct association path**

```bash
watchdog_pid="$(sudo launchctl print system/com.eisenhower.wifi-watchdog |
  awk '/pid =/ {print $3; exit}')"
ps -o pid=,command= -p "$watchdog_pid"
active_watchdog="$(ps -o command= -p "$watchdog_pid" | awk '{print $2}')"
if rg -n 'setairportnetwork|find-generic-password|password=' "$active_watchdog"; then
  exit 1
fi
```

Expected: the packaged watchdog is the only launchd argument and the forbidden scan is empty.

- [ ] **Step 5: Disarm the activation failsafe only after all gates pass**

```bash
failsafe_pid="$(sudo cat /var/db/eisenhower-cutover/native-first/failsafe.pid)"
sudo kill "$failsafe_pid"
if sudo kill -0 "$failsafe_pid" 2>/dev/null; then exit 1; fi
```

Expected: the failsafe is stopped only after local verification succeeds. If any bound fails, leave the failsafe armed or activate the saved watchdog-disabled rollback immediately.

### Task 8: Run controlled native recovery tests

**Files:** No repository changes. Run only in the approved local-console Wi-Fi test window. Do not change the router in this task.

- [ ] **Step 1: Verify launchd restart without network disruption**

```bash
before_pid="$(sudo launchctl print system/com.eisenhower.wifi-watchdog |
  awk '/pid =/ {print $3; exit}')"
sudo kill "$before_pid"
after_pid=''
for _ in {1..30}; do
  after_pid="$(sudo launchctl print system/com.eisenhower.wifi-watchdog 2>/dev/null |
    awk '/pid =/ {print $3; exit}')"
  if [[ -n "$after_pid" && "$after_pid" != "$before_pid" ]]; then break; fi
  sleep 1
done
test -n "$after_pid"
test "$after_pid" != "$before_pid"
sudo grep -Fq 'state=healthy' /var/db/eisenhower/wifi-watchdog.status
```

Expected: launchd replaces the process and the healthy contract causes no Wi-Fi command.

- [ ] **Step 2: Arm a three-minute watchdog-disabled rollback before each fault**

```bash
sudo /bin/sh -c '
  sleep 180
  rollback_system="$(cat /var/db/eisenhower-cutover/native-first/rollback-system)"
  wifi_device="$(cat /var/db/eisenhower-cutover/native-first/wifi-device)"
  wifi_service="$(cat /var/db/eisenhower-cutover/native-first/wifi-service)"
  case "$wifi_device" in en[0-9]*) ;; *) exit 1 ;; esac
  test -n "$wifi_service"
  /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --set "$rollback_system"
  "$rollback_system/activate"
  /usr/sbin/networksetup -setnetworkserviceenabled "$wifi_service" on
  /usr/sbin/networksetup -setairportpower "$wifi_device" on
' >/var/tmp/eisenhower-native-first-fault-failsafe.log 2>&1 &
fault_failsafe_pid=$!
sudo kill -0 "$fault_failsafe_pid"
```

Keep the local Terminal open. Do not use SSH as the recovery route.

- [ ] **Step 3: Prove unlocked radio recovery**

From the local console, leave the screen unlocked and run:

```bash
wifi_device="$(sudo cat /var/db/eisenhower-cutover/native-first/wifi-device)"
sudo /usr/sbin/networksetup -setairportpower "$wifi_device" off
```

Expected within 90 seconds: the watchdog records `radio_disabled`, enables the radio, records `native_autojoin_wait`, and native macOS logs show Auto-Join success. The watchdog never runs `setairportnetwork`. The expected address, gateway, DNS, HTTPS, local Terminal, SSH, and Aura recover. Roll back immediately if the bound fails.

- [ ] **Step 4: Prove locked radio recovery**

Arm a new fault failsafe. From the local recovery Terminal, schedule the fault before locking:

```bash
sudo /bin/sh -c '
  sleep 15
  wifi_device="$(cat /var/db/eisenhower-cutover/native-first/wifi-device)"
  case "$wifi_device" in en[0-9]*) ;; *) exit 1 ;; esac
  /usr/sbin/networksetup -setairportpower "$wifi_device" off
' >/var/tmp/eisenhower-locked-radio-fault.log 2>&1 &
locked_fault_pid=$!
sudo kill -0 "$locked_fault_pid"
```

Lock the screen with Control-Command-Q. From the secondary observer, verify the exact lock state:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 192.168.50.140 \
  '/usr/sbin/ioreg -l -w 0 | /usr/bin/grep -q '\''CGSSessionScreenIsLocked"=Yes'\'''
```

Expected within 90 seconds: the same causal sequence and health evidence as the unlocked test. Unlock only after the observation completes.

- [ ] **Step 5: Prove network-service restoration**

Arm a new fault failsafe, then run locally:

```bash
wifi_service="$(sudo cat /var/db/eisenhower-cutover/native-first/wifi-service)"
test -n "$wifi_service"
sudo /usr/sbin/networksetup -setnetworkserviceenabled "$wifi_service" off
```

Expected within 90 seconds: `service_disabled`, service enablement, `native_autojoin_wait`, native Auto-Join success, full network contract, SSH, and Aura. No direct association command appears.

- [ ] **Step 6: Verify causality and redaction**

```bash
sudo log show --last 20m --style compact \
  --predicate 'eventMessage CONTAINS "component=wifi-watchdog"'
sudo log show --last 20m --style compact \
  --predicate 'process == "airportd" AND eventMessage CONTAINS[c] "auto-join"'
sudo sed -n '1,20p' /var/db/eisenhower/wifi-watchdog.status
if sudo grep -R -n -E 'password=|find-generic-password|setairportnetwork' \
  /var/db/eisenhower /var/log/eisenhower-wifi-watchdog* 2>/dev/null; then
  exit 1
fi
```

Expected: each test has a loss event, watchdog recovery action, native Auto-Join event, and restored contract. Logs contain no password, unrelated SSID, direct association, or Keychain output.

- [ ] **Step 7: Disarm each fault failsafe only after local proof**

```bash
sudo kill "$fault_failsafe_pid"
if sudo kill -0 "$fault_failsafe_pid" 2>/dev/null; then exit 1; fi
```

### Task 9: Run the separate reboot and access-point outage window

**Files:** No repository changes. This task requires a separate explicit reboot and router-change authorization.

- [ ] **Step 1: Reboot with local recovery available**

Record `kern.boottime`, active closure, status, and Aura state. Confirm no critical operation is active. Reboot from the local console. After return, verify the changed boot time, active corrected closure, both Eisenhower launchd jobs before user interaction, native target recovery, complete network contract, sleep prevention, SSH, and Aura.

- [ ] **Step 2: Prove access-point outage and recovery**

With Eisenhower at the local console and the watchdog-disabled rollback ready, turn off only the target access point through its normal administrative control. Do not change the SSID, security mode, or password.

Expected: the watchdog waits 30 seconds, cycles the radio once, and retries with `60, 120, 300` second backoff. It never invokes direct association and never stops permanently.

Restore the access point during the 300-second backoff. Expected: native Auto-Join restores the approved network contract within 330 seconds. Verify the exact target in System Settings or the target access point's client view without listing unrelated networks.

- [ ] **Step 3: Complete final audit**

Verify:

```text
configuration_evaluation=PASS
unit_regressions=PASS
closure_scan=PASS
launchd_restart=PASS
unlocked_radio_recovery=PASS
locked_radio_recovery=PASS
service_recovery=PASS
reboot_recovery=PASS
access_point_recovery=PASS
sleep_prevention=PASS
credential_redaction=PASS
aura_health=PASS
rollback_readiness=PASS
protected_files=PASS
final_audit=PASS
```

Do not report completion when only final connectivity is healthy. Each recovery test requires causal watchdog and native Auto-Join evidence.

## Immediate rollback

From the local console:

```bash
rollback_system="$(sudo cat /var/db/eisenhower-cutover/native-first/rollback-system)"
wifi_device="$(sudo cat /var/db/eisenhower-cutover/native-first/wifi-device)"
wifi_service="$(sudo cat /var/db/eisenhower-cutover/native-first/wifi-service)"
case "$rollback_system" in /nix/store/*-darwin-system-*) ;; *) exit 1 ;; esac
case "$wifi_device" in en[0-9]*) ;; *) exit 1 ;; esac
test -n "$wifi_service"
sudo /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --set "$rollback_system"
sudo "$rollback_system/activate"
sudo /usr/sbin/networksetup -setnetworkserviceenabled "$wifi_service" on
sudo /usr/sbin/networksetup -setairportpower "$wifi_device" on
```

Expected: the watchdog-disabled closure is active. Native macOS Auto-Join owns recovery. No rollback command contains an SSID or password. If native Auto-Join does not recover, select `Schrödinger’s WiFi` manually through System Settings; do not inspect or pass the credential.
