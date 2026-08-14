#!/usr/bin/env bash
set -euo pipefail

test_dir="$(mktemp -d)"
watchdog_pid=''
cleanup() {
  if [[ -n "$watchdog_pid" ]] && kill -0 "$watchdog_pid" 2>/dev/null; then
    kill "$watchdog_pid"
    wait "$watchdog_pid" 2>/dev/null || true
  fi
  rm -rf "$test_dir"
}
trap cleanup EXIT
fake_bin="$test_dir/bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/networksetup" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  -listallhardwareports)
    printf 'Hardware Port: Wi-Fi\nDevice: en7\n'
    ;;
  -listpreferredwirelessnetworks)
    printf 'Preferred networks on %s:\n' "$2"
    if [[ "${FAKE_PREFERRED:-yes}" == yes ]]; then
      printf '\tSchrödinger’s WiFi\n'
    else
      printf '\tUnrelated Network SECRET_SENTINEL\n'
    fi
    ;;
  -listnetworkserviceorder)
    printf '(1) Unrelated Ethernet\n'
    printf '(Hardware Port: Ethernet, Device: en9)\n'
    if [[ "${FAKE_SERVICE_ORDER_DISABLED:-no}" == yes ]]; then
      printf '(*) %s\n' "${FAKE_SERVICE_NAME:-Wi-Fi}"
    else
      printf '(2) %s\n' "${FAKE_SERVICE_NAME:-Wi-Fi}"
    fi
    printf '(Hardware Port: Wi-Fi, Device: en7)\n'
    ;;
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
  -setairportnetwork)
    printf 'forbidden_direct_association %s\n' "$*" >>"$FAKE_CALLS"
    exit 70
    ;;
  *)
    exit 64
    ;;
esac
SH

cat >"$fake_bin/ifconfig" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
link_state="$(cat "$FAKE_LINK_STATE_FILE")"
if [[ "$link_state" == active ]]; then
  printf 'inet %s netmask %s broadcast 192.168.50.255\n' \
    "$(cat "$FAKE_IPV4_FILE")" "${FAKE_NETMASK:-0xffffff00}"
  printf 'status: active\n'
else
  printf 'status: inactive\n'
fi
SH

cat >"$fake_bin/ipconfig" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${FAKE_ADDRESS_STATE:-ready}" == ready ]]; then
  cat "$FAKE_IPV4_FILE"
fi
SH

cat >"$fake_bin/route" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'route\n' >>"$FAKE_HEALTH_CALLS"
printf '   route to: default\n'
printf 'destination: default\n'
printf '    gateway: %s\n' "$(cat "$FAKE_GATEWAY_FILE")"
printf '  interface: %s\n' "$(cat "$FAKE_ROUTE_INTERFACE_FILE")"
SH

cat >"$fake_bin/dscacheutil" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'dns\n' >>"$FAKE_HEALTH_CALLS"
if [[ "${FAKE_DNS_STATE:-ready}" == ready ]]; then
  printf 'ip_address: 192.0.2.1\n'
else
  exit 1
fi
SH

cat >"$fake_bin/curl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'https\n' >>"$FAKE_HEALTH_CALLS"
[[ "${FAKE_HTTPS_STATE:-ready}" == ready ]]
SH

cat >"$fake_bin/nc" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'management\n' >>"$FAKE_HEALTH_CALLS"
[[ "${FAKE_MANAGEMENT_STATE:-ready}" == ready ]]
SH

cat >"$fake_bin/logger" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$FAKE_LOG"
SH

cat >"$fake_bin/sleep" <<'SH'
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
SH

chmod +x "$fake_bin"/*

watchdog="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wifi-watchdog.sh"
expected_ssid_sha256='8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d'
actual_ssid="$(sed -n "s/^readonly target_ssid='\(.*\)'$/\1/p" "$watchdog")"
test "$(printf '%s' "$actual_ssid" | shasum -a 256 | awk '{print $1}')" = \
  "$expected_ssid_sha256"

export EISENHOWER_NETWORKSETUP="$fake_bin/networksetup"
export EISENHOWER_IFCONFIG="$fake_bin/ifconfig"
export EISENHOWER_IPCONFIG="$fake_bin/ipconfig"
export EISENHOWER_ROUTE="$fake_bin/route"
export EISENHOWER_DSCACHEUTIL="$fake_bin/dscacheutil"
export EISENHOWER_CURL="$fake_bin/curl"
export EISENHOWER_NC="$fake_bin/nc"
export EISENHOWER_LOGGER="$fake_bin/logger"
export EISENHOWER_SLEEP="$fake_bin/sleep"
export EISENHOWER_STATUS_FILE="$test_dir/status"
export FAKE_CALLS="$test_dir/calls"
export FAKE_LOG="$test_dir/log"
export FAKE_SLEEPS="$test_dir/sleeps"
export FAKE_HEALTH_CALLS="$test_dir/health-calls"

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
  export FAKE_SERVICE_ORDER_DISABLED=no FAKE_ADDRESS_STATE=ready
  export FAKE_NETMASK=0xffffff00 FAKE_DNS_STATE=ready
  export FAKE_HTTPS_STATE=ready FAKE_MANAGEMENT_STATE=ready
  unset FAKE_RECOVER_AT_SLEEP_COUNT FAKE_SLEEP_LIMIT
}

assert_no_direct_association() {
  if grep -Fq forbidden_direct_association "$FAKE_CALLS"; then
    exit 1
  fi
}

reset_case
bash "$watchdog" --once
test ! -s "$FAKE_CALLS"
grep -Fq 'state=healthy' "$EISENHOWER_STATUS_FILE"
for expected_call in route management dns https; do
  grep -Fqx "$expected_call" "$FAKE_HEALTH_CALLS"
done

reset_case
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
printf '198.51.100.140\n' >"$FAKE_IPV4_FILE"
printf '198.51.100.1\n' >"$FAKE_GATEWAY_FILE"
printf 'en9\n' >"$FAKE_ROUTE_INTERFACE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=5
bash "$watchdog" --once
test ! -s "$FAKE_CALLS"
grep -Fq 'transition=native_autojoin_wait' "$FAKE_LOG"
grep -Fq 'state=healthy' "$EISENHOWER_STATUS_FILE"

reset_case
printf 'Disabled\n' >"$FAKE_SERVICE_STATE_FILE"
export FAKE_SERVICE_ORDER_DISABLED=yes
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=5
bash "$watchdog" --once
test "$(sed -n '1p' "$FAKE_CALLS")" = \
  '-setnetworkserviceenabled Primary Wireless on'
grep -Fqx Enabled "$FAKE_SERVICE_STATE_FILE"
grep -Fq 'transition=service_disabled' "$FAKE_LOG"
grep -Fq 'transition=service_restored' "$FAKE_LOG"
assert_no_direct_association

reset_case
printf 'Off\n' >"$FAKE_RADIO_STATE_FILE"
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=5
bash "$watchdog" --once
grep -Fqx -- '-setairportpower en7 on' "$FAKE_CALLS"
grep -Fq 'transition=radio_disabled' "$FAKE_LOG"
grep -Fq 'transition=radio_restored' "$FAKE_LOG"
assert_no_direct_association

reset_case
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=35
bash "$watchdog" --once
test "$(grep -Fc -- '-setairportpower en7 off' "$FAKE_CALLS")" = 1
test "$(grep -Fc -- '-setairportpower en7 on' "$FAKE_CALLS")" = 1
grep -Fq 'transition=radio_cycle' "$FAKE_LOG"
grep -Fq 'recovery_trigger=radio_cycle' "$EISENHOWER_STATUS_FILE"
assert_no_direct_association

for rejected_contract in address subnet gateway route management; do
  reset_case
  case "$rejected_contract" in
    address)
      printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
      expected_component=address
      ;;
    subnet)
      export FAKE_NETMASK=0xffff0000
      expected_component=address
      ;;
    gateway)
      printf '192.168.60.1\n' >"$FAKE_GATEWAY_FILE"
      expected_component=route
      ;;
    route)
      printf 'en9\n' >"$FAKE_ROUTE_INTERFACE_FILE"
      expected_component=route
      ;;
    management)
      export FAKE_MANAGEMENT_STATE=failed
      expected_component=management
      ;;
  esac
  if bash "$watchdog" --once; then exit 1; fi
  grep -Fq 'state=native_recovery_failed' "$EISENHOWER_STATUS_FILE"
  grep -Fq "failed_component=$expected_component" "$EISENHOWER_STATUS_FILE"
  test "$(grep -Fc -- '-setairportpower en7 off' "$FAKE_CALLS")" = 1
  test "$(grep -Fc -- '-setairportpower en7 on' "$FAKE_CALLS")" = 1
  assert_no_direct_association
done

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
  grep -Fq "failed_component=$online_failure" "$EISENHOWER_STATUS_FILE"
done

reset_case
export FAKE_PREFERRED=no
if bash "$watchdog" --once; then exit 1; fi
test ! -s "$FAKE_CALLS"
grep -Fq 'state=preferred_target_unavailable' "$EISENHOWER_STATUS_FILE"
if grep -Fq 'SECRET_SENTINEL' "$FAKE_LOG" "$EISENHOWER_STATUS_FILE"; then
  exit 1
fi

expected=(60 120 300 300)
for index in "${!expected[@]}"; do
  test "$(bash "$watchdog" --print-backoff "$((index + 1))")" = \
    "${expected[$index]}"
done

reset_case
bash "$watchdog" --wait-healthy en7
test "$(paste -sd, "$FAKE_SLEEPS")" = 30

reset_case
printf 'inactive\n' >"$FAKE_LINK_STATE_FILE"
export FAKE_RECOVER_AT_SLEEP_COUNT=65
bash "$watchdog" &
watchdog_pid="$!"
observed_recovery=no
for _ in {1..200}; do
  if grep -Fq 'state=healthy failures=0 next_retry_seconds=30' "$FAKE_LOG"; then
    observed_recovery=yes
    break
  fi
  /bin/sleep 0.01
done
kill "$watchdog_pid"
wait "$watchdog_pid" 2>/dev/null || true
watchdog_pid=''
test "$observed_recovery" = yes
grep -Fq \
  'state=native_recovery_failed failures=1 next_retry_seconds=60' "$FAKE_LOG"
grep -Fq 'state=healthy failures=0 next_retry_seconds=30' "$FAKE_LOG"
grep -Fq 'state=healthy' "$EISENHOWER_STATUS_FILE"

if rg -n 'setairportnetwork|find-generic-password|password=' "$watchdog"; then
  exit 1
fi

echo "Wi-Fi watchdog tests: PASS"
