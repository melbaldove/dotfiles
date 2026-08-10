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
  -listallhardwareports)
    printf 'Hardware Port: Wi-Fi\nDevice: en7\n'
    ;;
  -listpreferredwirelessnetworks)
    printf 'Preferred networks on %s:\n' "$2"
    if [[ "${FAKE_PREFERRED:-yes}" == yes ]]; then
      printf '\tSchrödinger’s WiFi\n'
    else
      printf '\tUnrelated Network\n'
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
    if [[ -n "${FAKE_SERVICE_STATE_FILE:-}" ]]; then
      cat "$FAKE_SERVICE_STATE_FILE"
    else
      printf '%s\n' "${FAKE_SERVICE_STATE:-Enabled}"
    fi
    ;;
  -setnetworkserviceenabled)
    printf '%s\n' "$*" >>"$FAKE_CALLS"
    if [[ -n "${FAKE_SERVICE_STATE_FILE:-}" ]]; then
      printf 'Enabled\n' >"$FAKE_SERVICE_STATE_FILE"
    fi
    ;;
  -setairportpower)
    printf '%s\n' "$*" >>"$FAKE_CALLS"
    ;;
  -getairportpower)
    printf 'Wi-Fi Power (%s): %s\n' "$2" "${FAKE_RADIO_STATE:-On}"
    ;;
  -setairportnetwork)
    printf '%s\n' "$*" >>"$FAKE_CALLS"
    printf '%s\n' "$#" >"$FAKE_ASSOC_ARGC"
    printf '%s\n' "$@" >"$FAKE_ASSOC_ARGS"
    case "${FAKE_ASSOC_RESULT:-success}" in
      success) ;;
      failure) exit 1 ;;
      success-with-failure-output)
        printf 'Failed to join network. diagnostic=SECRET_SENTINEL\n' >&2
        ;;
      *) exit 64 ;;
    esac
    ;;
  *)
    exit 64
    ;;
esac
SH

cat >"$fake_bin/ifconfig" <<'SH'
#!/usr/bin/env bash
if [[ "${FAKE_LINK_STATE:-active}" == active ]]; then
  printf 'status: active\n'
else
  printf 'status: inactive\n'
fi
SH

cat >"$fake_bin/ipconfig" <<'SH'
#!/usr/bin/env bash
if [[ "${FAKE_ADDRESS_STATE:-ready}" == ready ]]; then
  printf '192.0.2.10\n'
fi
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
  if (( count >= FAKE_SLEEP_LIMIT )); then
    exit 99
  fi
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
export FAKE_ASSOC_ARGS="$test_dir/args" FAKE_LOG="$test_dir/log"
export FAKE_SLEEPS="$test_dir/sleeps"

reset_case() {
  : >"$FAKE_CALLS"
  : >"$FAKE_LOG"
  : >"$FAKE_SLEEPS"
  rm -f "$FAKE_ASSOC_ARGC" "$FAKE_ASSOC_ARGS" "$EISENHOWER_STATUS_FILE"
  export FAKE_PREFERRED=yes FAKE_SERVICE_STATE=Enabled FAKE_RADIO_STATE=On
  export FAKE_SERVICE_ORDER_DISABLED=no FAKE_SERVICE_STATE_FILE=
  export FAKE_SERVICE_NAME='Wi-Fi'
  export FAKE_LINK_STATE=active FAKE_ADDRESS_STATE=ready
  export FAKE_ASSOC_RESULT=success
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
export FAKE_ASSOC_RESULT=success-with-failure-output
if bash "$watchdog" --once; then exit 1; fi
grep -Fq 'state=authentication_failed' "$EISENHOWER_STATUS_FILE"
if grep -R -n -F 'SECRET_SENTINEL' "$EISENHOWER_STATUS_FILE" "$FAKE_LOG"; then
  exit 1
fi

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
service_state_file="$test_dir/service-state"
printf 'Enabled: No\n' >"$service_state_file"
export FAKE_SERVICE_STATE_FILE="$service_state_file"
export FAKE_SERVICE_NAME='Primary Wireless'
export FAKE_SERVICE_ORDER_DISABLED=yes
bash "$watchdog" --once
grep -Fq -- '-setnetworkserviceenabled Primary Wireless on' "$FAKE_CALLS"
grep -Fqx Enabled "$service_state_file"
if grep -Fq 'Unrelated Ethernet' "$FAKE_LOG"; then exit 1; fi

reset_case
printf 'Enabled: No\n' >"$service_state_file"
export FAKE_SERVICE_STATE_FILE="$service_state_file"
export FAKE_SERVICE_NAME='Primary Wireless'
export FAKE_SERVICE_ORDER_DISABLED=yes
bash "$watchdog" &
watchdog_pid="$!"
observed_intervals=0
for _ in {1..200}; do
  observed_intervals="$(wc -l <"$FAKE_SLEEPS" | tr -d ' ')"
  if (( observed_intervals >= 31 )); then
    break
  fi
  /bin/sleep 0.01
done
kill "$watchdog_pid"
wait "$watchdog_pid" 2>/dev/null || true
test "$observed_intervals" -ge 31
test "$(grep -Fc -- '-setnetworkserviceenabled Primary Wireless on' "$FAKE_CALLS")" = 1
test "$(grep -Fc -- '-setairportnetwork en7 Schrödinger’s WiFi' "$FAKE_CALLS")" = 1
grep -Fqx Enabled "$service_state_file"
unset FAKE_SERVICE_STATE_FILE

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
  test "$(bash "$watchdog" --print-backoff "$((index + 1))")" = \
    "${expected[$index]}"
done

if grep -R -n -E 'find-generic-password|password=' "$watchdog" "$FAKE_LOG"; then
  exit 1
fi

echo "Wi-Fi watchdog tests: PASS"
