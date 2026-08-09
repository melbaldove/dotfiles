#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"

baseline_file="${PROTECTED_BASELINE_FILE:-/tmp/eisenhower-protected-files.sha256}"
if [[ -f "$baseline_file" ]]; then
  shasum -a 256 -c "$baseline_file"
fi

# shellcheck disable=SC1112 # U+2019 is required by the approved SSID.
test "$(printf '%s' 'Schrödinger’s WiFi' | shasum -a 256 | awk '{print $1}')" = \
  8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d
test "$(nix eval --raw .#darwinConfigurations.turing.config.networking.hostName)" = turing
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.networking.hostName)" = eisenhower
test "$(nix eval --raw .#darwinConfigurations.eisenhower.config.nixpkgs.hostPlatform.system)" = aarch64-darwin

echo "Darwin host boundary: PASS"
