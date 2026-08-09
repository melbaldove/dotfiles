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
  case "$1" in
    1) echo 5 ;;
    2) echo 10 ;;
    3) echo 20 ;;
    4) echo 40 ;;
    5) echo 60 ;;
    6) echo 120 ;;
    *) echo 300 ;;
  esac
}

write_status() {
  local state="$1" failures="$2" delay="$3" tmp
  umask 077
  mkdir -p "$(dirname "$status_file")"
  tmp="${status_file}.$$"
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
    sed '1d; s/^[[:space:]]*//' |
    grep -Fqx -- "$target_ssid"
}

link_is_active() {
  "$ifconfig_bin" "$1" 2>/dev/null | grep -Fq 'status: active'
}

wait_healthy_interval() {
  local device="$1"
  for _ in {1..30}; do
    "$sleep_bin" 1
    if ! link_is_active "$device"; then
      return 1
    fi
  done
}

has_usable_ipv4() {
  local address
  address="$($ipconfig_bin getifaddr "$1" 2>/dev/null || true)"
  [[ -n "$address" && "$address" != 169.254.* ]]
}

record_transition() {
  "$logger_bin" -t com.eisenhower.wifi-watchdog \
    "component=wifi-watchdog transition=$1" >/dev/null 2>&1 || true
}

ensure_service_and_radio() {
  local device="$1"
  if ! "$networksetup_bin" -getnetworkserviceenabled "$network_service" 2>/dev/null |
    grep -Fq Enabled; then
    record_transition service_disabled
    "$networksetup_bin" -setnetworkserviceenabled "$network_service" on \
      >/dev/null 2>&1 || return 1
  fi
  if ! "$networksetup_bin" -getairportpower "$device" 2>/dev/null |
    grep -Fq ': On'; then
    record_transition radio_disabled
    "$networksetup_bin" -setairportpower "$device" on >/dev/null 2>&1 || return 1
  fi
}

associate_target() {
  local device="$1"
  if ! "$networksetup_bin" -setairportnetwork "$device" "$target_ssid" \
    >/dev/null 2>&1; then
    last_state=authentication_failed
    return 1
  fi
  last_asserted_at="$(date +%s)"
  for _ in {1..15}; do
    if link_is_active "$device" && has_usable_ipv4 "$device"; then
      last_state=healthy
      return 0
    fi
    "$sleep_bin" 1
  done
  last_state=associated_no_address
  return 1
}

check_once() {
  local device now
  device="$(wifi_device)"
  if [[ -z "$device" ]]; then
    last_state=interface_missing
    return 1
  fi
  if ! target_is_preferred "$device"; then
    last_state=credential_unavailable
    return 1
  fi
  if ! ensure_service_and_radio "$device"; then
    last_state=command_failed
    return 1
  fi
  now="$(date +%s)"
  if link_is_active "$device" && has_usable_ipv4 "$device" &&
    (( now - last_asserted_at < reassert_interval )); then
    last_state=healthy
    return 0
  fi
  associate_target "$device"
}

case "${1:-}" in
  --print-backoff)
    backoff_for "${2:?failure count required}"
    exit 0
    ;;
  --wait-healthy)
    wait_healthy_interval "${2:?device required}"
    exit $?
    ;;
  --once)
    if check_once; then
      write_status "$last_state" 0 0
      exit 0
    fi
    write_status "$last_state" 1 "$(backoff_for 1)"
    exit 1
    ;;
  "") ;;
  *) exit 64 ;;
esac

failures=0
while true; do
  if check_once; then
    failures=0
    write_status healthy 0 "$healthy_interval"
    if ! wait_healthy_interval "$(wifi_device)"; then
      continue
    fi
  else
    failures=$((failures + 1))
    delay="$(backoff_for "$failures")"
    write_status "$last_state" "$failures" "$delay"
    "$sleep_bin" "$delay"
  fi
done
