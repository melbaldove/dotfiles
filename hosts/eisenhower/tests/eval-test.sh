#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"

baseline_file="${PROTECTED_BASELINE_FILE:-/tmp/eisenhower-protected-files.sha256}"
if [[ -f "$baseline_file" ]]; then
  shasum -a 256 -c "$baseline_file"
  test "$(nix eval --raw .#darwinConfigurations.turing.config.networking.hostName)" = turing
fi

# shellcheck disable=SC1112 # U+2019 is required by the approved SSID.
test "$(printf '%s' 'Schrödinger’s WiFi' | shasum -a 256 | awk '{print $1}')" = \
  8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d
darwin_outputs="$(nix eval --json .#darwinConfigurations \
  --apply 'outputs: builtins.attrNames outputs')"
jq -e 'index("turing") != null and index("eisenhower") != null' \
  <<<"$darwin_outputs" >/dev/null
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.networking.hostName)" = eisenhower
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.nixpkgs.hostPlatform.system)" = aarch64-darwin
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.power.sleep.computer)" = never
test "$(nix eval --json .#darwinConfigurations.eisenhower.config.power.sleep.allowSleepByPowerButton)" = false
power_job="$(nix eval --json .#darwinConfigurations.eisenhower.config.launchd.daemons.eisenhower-prevent-idle-sleep.serviceConfig)"
jq -e '.Label == "com.eisenhower.prevent-idle-sleep"' <<<"$power_job" >/dev/null
jq -e '.ProgramArguments == ["/usr/bin/caffeinate", "-i"]' <<<"$power_job" >/dev/null
jq -e '.RunAtLoad == true and .KeepAlive == true' <<<"$power_job" >/dev/null
wifi_job="$(nix eval --json .#darwinConfigurations.eisenhower.config.launchd.daemons.eisenhower-wifi-watchdog.serviceConfig)"
jq -e '.Label == "com.eisenhower.wifi-watchdog"' <<<"$wifi_job" >/dev/null
jq -e '.RunAtLoad == true and .KeepAlive == true and .ThrottleInterval == 30' <<<"$wifi_job" >/dev/null
jq -e '.ProgramArguments | length == 1' <<<"$wifi_job" >/dev/null
jq -e '.ProgramArguments[0] | endswith("/bin/eisenhower-wifi-watchdog")' <<<"$wifi_job" >/dev/null
jq -e '.EnvironmentVariables == null' <<<"$wifi_job" >/dev/null
if grep -Eqi 'password|find-generic-password' <<<"$wifi_job"; then
  exit 1
fi

test "$(nix eval --json .#darwinConfigurations.eisenhower.config.services.tailscale.enable)" = true
test "$(nix eval --json .#darwinConfigurations.eisenhower.config.services.openssh.enable)" = true

tailscale_job="$(nix eval --json \
  .#darwinConfigurations.eisenhower.config.launchd.daemons.tailscaled.serviceConfig)"
jq -e '.Label == "com.tailscale.tailscaled" and .RunAtLoad == true' \
  <<<"$tailscale_job" >/dev/null

authorized_keys="$(nix eval --json \
  .#darwinConfigurations.eisenhower.config.users.users.melbournebaldove.openssh.authorizedKeys.keys)"
jq -e --arg key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local' \
  'index($key) != null' <<<"$authorized_keys" >/dev/null

test "$(nix eval --raw \
  .#darwinConfigurations.turing.config.home-manager.users.melbournebaldove.programs.ssh.matchBlocks.einstein.data.hostname)" = \
  einstein.tail141ab8.ts.net
test "$(nix eval --raw \
  .#darwinConfigurations.turing.config.home-manager.users.melbournebaldove.programs.ssh.matchBlocks.eisenhower.data.hostname)" = \
  eisenhower.tail141ab8.ts.net

if rg -n -i 'wireguard|10\.0\.0\.|10\.0\.1\.|shannon|feynman' \
  hosts/turing \
  modules/system/darwin \
  users/melbournebaldove/dev.nix \
  scripts \
  AGENTS.md \
  CLAUDE.md; then
  exit 1
fi

echo "Darwin host boundary: PASS"
