#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1112 # U+2019 is required by the approved SSID.
readonly target_ssid='Schrödinger’s WiFi'
readonly healthy_interval=30
readonly native_recovery_window=30
readonly radio_cycle_off_seconds=2
readonly expected_ipv4='192.168.50.140'
readonly expected_netmask='0xffffff00'
readonly expected_gateway='192.168.50.1'
readonly health_dns_name='cache.nixos.org'
readonly health_https_url='https://cache.nixos.org/nix-cache-info'
readonly management_port=22

networksetup_bin="${EISENHOWER_NETWORKSETUP:-/usr/sbin/networksetup}"
ifconfig_bin="${EISENHOWER_IFCONFIG:-/sbin/ifconfig}"
ipconfig_bin="${EISENHOWER_IPCONFIG:-/usr/sbin/ipconfig}"
route_bin="${EISENHOWER_ROUTE:-/sbin/route}"
dscacheutil_bin="${EISENHOWER_DSCACHEUTIL:-/usr/bin/dscacheutil}"
curl_bin="${EISENHOWER_CURL:-/usr/bin/curl}"
nc_bin="${EISENHOWER_NC:-/usr/bin/nc}"
logger_bin="${EISENHOWER_LOGGER:-/usr/bin/logger}"
sleep_bin="${EISENHOWER_SLEEP:-/bin/sleep}"
status_file="${EISENHOWER_STATUS_FILE:-/var/db/eisenhower/wifi-watchdog.status}"

last_state=command_failed
last_trigger=none
last_component='command'

backoff_for() {
  case "$1" in
    1) echo 60 ;;
    2) echo 120 ;;
    *) echo 300 ;;
  esac
}

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

wifi_device() {
  "$networksetup_bin" -listallhardwareports 2>/dev/null |
    awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}'
}

wifi_service() {
  "$networksetup_bin" -listnetworkserviceorder 2>/dev/null |
    awk -v device="$1" '
      /^\(([[:digit:]]+|\*)\) / {
        service = $0
        sub(/^\(([[:digit:]]+|\*)\) /, "", service)
        sub(/^\*/, "", service)
        next
      }
      index($0, "Device: " device ")") {
        print service
        exit
      }
    '
}

service_is_enabled() {
  "$networksetup_bin" -getnetworkserviceenabled "$1" 2>/dev/null |
    grep -Fqx Enabled
}

target_is_preferred() {
  "$networksetup_bin" -listpreferredwirelessnetworks "$1" 2>/dev/null |
    sed '1d; s/^[[:space:]]*//' |
    grep -Fqx -- "$target_ssid"
}

radio_is_on() {
  "$networksetup_bin" -getairportpower "$1" 2>/dev/null |
    grep -Fq ': On'
}

link_is_active() {
  "$ifconfig_bin" "$1" 2>/dev/null | grep -Fq 'status: active'
}

has_expected_ipv4_and_subnet() {
  local address
  address="$($ipconfig_bin getifaddr "$1" 2>/dev/null || true)"
  if [[ "$address" != "$expected_ipv4" ]]; then
    return 1
  fi
  "$ifconfig_bin" "$1" 2>/dev/null |
    awk -v address="$expected_ipv4" -v netmask="$expected_netmask" '
      $1 == "inet" && $2 == address && $4 == netmask { found = 1 }
      END { exit !found }
    '
}

default_route_matches() {
  local device="$1" route_output
  route_output="$($route_bin -n get default 2>/dev/null)" || return 1
  grep -Eq "^[[:space:]]*gateway:[[:space:]]+$expected_gateway$" \
    <<<"$route_output" &&
    grep -Eq "^[[:space:]]*interface:[[:space:]]+$device$" \
      <<<"$route_output"
}

dns_works() {
  "$dscacheutil_bin" -q host -a name "$health_dns_name" 2>/dev/null |
    grep -Eq '^[[:space:]]*ip_address:'
}

https_works() {
  "$curl_bin" -fsS --max-time 10 "$health_https_url" >/dev/null 2>&1
}

management_is_reachable() {
  "$nc_bin" -z -w 3 "$expected_ipv4" "$management_port" >/dev/null 2>&1
}

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
  network_identity_is_healthy "$device" && online_services_are_healthy
}

ensure_service_and_radio() {
  local device="$1" service service_ready radio_ready
  service="$(wifi_service "$device")"
  if [[ -z "$service" ]]; then
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
    if [[ "$service_ready" != true ]]; then
      return 1
    fi
    last_trigger=service_restored
    record_transition service_restored
  fi
  if ! radio_is_on "$device"; then
    record_transition radio_disabled
    "$networksetup_bin" -setairportpower "$device" on \
      >/dev/null 2>&1 || return 1
    radio_ready=false
    for _ in {1..5}; do
      if radio_is_on "$device"; then
        radio_ready=true
        break
      fi
      "$sleep_bin" 1
    done
    if [[ "$radio_ready" != true ]]; then
      return 1
    fi
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
    last_component='command'
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
    last_component='command'
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

wait_healthy_interval() {
  local device="$1"
  "$sleep_bin" "$healthy_interval"
  network_contract_is_healthy "$device"
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
