# Eisenhower Sleep and Wi-Fi Recovery Design

Date: 2026-08-09

Status: Approved design pending final written-spec review

## Purpose

This design makes the existing macOS host Eisenhower resilient during normal operation.

It has two required properties:

1. Eisenhower does not enter system sleep because of idle time.
2. Eisenhower continuously tries to connect to the exact Wi-Fi SSID `Schrödinger’s WiFi`.

This document defines the design and its verification. It does not authorize implementation.

## Source evidence

The `.dotfiles` repository and the live host have different identity names:

- The flake exposes `darwinConfigurations.turing`.
- The host module declares `networking.hostName = "turing"`.
- The live host identifies as `eisenhower.local`.

The evaluated Darwin configuration does not declare a sleep policy. Each `power.sleep.*` value is `null`.

The live host has these unmanaged controls:

- `pmset` reports `sleep = 0` for battery and AC power.
- `com.local.nosleep` applies idle-sleep, display-sleep, and disk-sleep values at load time.
- `com.aura.caffeinate` runs `caffeinate -s` with `KeepAlive`.

The live host has no Wi-Fi recovery job. Its Wi-Fi metadata has exactly one user-preferred network identity: `Schrödinger’s WiFi`.

Darwin secret management is manual. The Darwin module installs `agenix`, but it does not declare or materialize secrets. The expected repository `secrets/` directory is not present in this checkout.

The repository has existing user changes in `codex/AGENTS.md`, `flake.lock`, and `hosts/turing/default.nix`. Future work must preserve those changes.

## Scope

### In scope

- Declarative idle-sleep prevention for battery and AC power.
- A launchd power assertion that survives process failure.
- Continuous connection attempts to `Schrödinger’s WiFi`.
- Recovery after boot, radio disablement, network-service interruption, disassociation, access-point loss, transient authentication failure, and temporary link loss.
- Bounded retry backoff with no terminal failure state.
- Sanitized status and log data.
- Safe live tests and rollback.

### Out of scope

- Display-sleep policy.
- Explicit administrator sleep commands.
- Sleep caused by lid closure.
- Shutdown caused by battery exhaustion.
- Internet-service availability after successful Wi-Fi association.
- Credential creation, rotation, or recovery.
- Host-definition renaming from `turing` to `eisenhower`.
- Changes to Aura behavior.

"Normal operation" means that Eisenhower is booted, its lid is open, and its battery is above the forced-shutdown threshold.

## Considered approaches

### Native settings only

This approach uses nix-darwin sleep settings and the native macOS preferred-network behavior.

It has a small configuration surface. It does not give controlled retry timing, durable failure evidence, or a direct way to test repeated authentication failures.

### Declarative settings plus a launchd watchdog

This approach uses nix-darwin for the sleep policy and two system launch daemons for live enforcement and Wi-Fi recovery.

It gives reproducible configuration, infinite retry, bounded backoff, sanitized evidence, and independent process recovery. It needs a small watchdog and a secure credential boundary.

This is the approved approach.

### Configuration profile or MDM

This approach installs a managed Wi-Fi profile and uses an external policy system.

It is suitable for a fleet. It adds unnecessary infrastructure and a second secret-management system for one personal machine.

## Architecture

The design has three units. Each unit has one purpose.

### Darwin power policy

The Eisenhower host configuration declares:

- computer sleep as `never`;
- sleep by the power button as disabled.

The policy applies to battery and AC power. Display sleep remains a separate user policy.

### Idle-sleep assertion daemon

A system launch daemon named `com.eisenhower.prevent-idle-sleep` runs an idle-sleep assertion.

The job has these properties:

- It starts during boot.
- It does not depend on user login.
- launchd keeps it alive.
- launchd restarts it after an unexpected exit.
- Its output contains no private data.

The Darwin power policy is the primary control. The assertion daemon is an independent runtime control and an observable signal.

The existing `com.local.nosleep` and `com.aura.caffeinate` jobs remain during the first activation. They are removed only after the new controls pass the reboot and runtime tests.

### Wi-Fi watchdog daemon

A root system launch daemon named `com.eisenhower.wifi-watchdog` runs before user login.

The watchdog does not hard-code `en0`. It discovers the hardware port named Wi-Fi and uses its current device name.

For each health check, it:

1. Finds the Wi-Fi device and service.
2. Enables the network service if it is disabled.
3. Enables the Wi-Fi radio if it is disabled.
4. Tests link state and IPv4 address state.
5. Starts an association attempt for the exact SSID `Schrödinger’s WiFi` if the link is not healthy.
6. Records a successful target association only after the association command succeeds and a usable IPv4 address exists.
7. Records a sanitized result.

The watchdog checks a healthy connection every 30 seconds.

The live host redacts its active SSID from command-line status tools, including privileged status calls. The watchdog does not depend on reading the active SSID. It actively selects the configured target at boot and after each unhealthy link state. It also reasserts the target every five minutes. This corrects a manual or automatic switch to another network without enumerating or logging other SSIDs.

After a failed association, it retries after these delays:

`5, 10, 20, 40, 60, 120, 300` seconds.

The delay remains at 300 seconds after later failures. The watchdog never enters a terminal failure state. A successful association resets the failure count and delay.

launchd restarts the watchdog if its process exits. A process restart causes one immediate health check. launchd throttling prevents a crash loop.

## Wi-Fi state model

The watchdog uses these states:

- `interface_missing`: macOS does not report a Wi-Fi hardware port.
- `credential_unavailable`: the credential file is missing or unsafe.
- `service_disabled`: the Wi-Fi network service is disabled.
- `radio_disabled`: the Wi-Fi radio is disabled.
- `access_point_unavailable`: the target SSID cannot be associated.
- `authentication_failed`: the association command reports an authentication failure.
- `associated_no_address`: the target SSID is associated, but it has no usable IPv4 address.
- `command_failed`: a required system command fails for another reason.
- `healthy`: the exact target SSID is associated and has a usable IPv4 address.

An upstream Internet outage does not cause authentication retries while the target Wi-Fi association remains healthy. Internet health is a separate property.

## Credential boundary

The Wi-Fi password must not enter:

- the Git repository;
- the Nix store;
- the generated launchd property list;
- a process argument;
- the unified log;
- the watchdog status file.

The approved design uses a root-owned credential file outside the Nix store. Its required file mode is `0400`. Credential provisioning is a separate, manual, approval-gated operation.

The watchdog reads the credential from standard input and passes it to the macOS association command through standard input. It does not place the password in an argument or environment variable.

If the credential file is absent, empty, not owned by root, or has unsafe permissions, the watchdog does not attempt authentication. It records `credential_unavailable` and continues bounded checks without exposing file contents.

## Observability

The watchdog writes structured, sanitized events to the macOS unified log.

Each event can contain:

- component name;
- state;
- attempt number;
- next retry delay;
- result class;
- last successful association time.

The watchdog also writes an atomic, root-owned status file. The status file contains the current state, failure count, retry delay, and timestamps.

Logs and status must not contain:

- the Wi-Fi password;
- BSSID values;
- unrelated SSIDs;
- nearby network lists;
- credential-file contents.

## Verification

### Configuration evaluation

Evaluate the Darwin configuration and confirm:

- computer sleep evaluates to `never`;
- power-button sleep evaluates to disabled;
- both launchd jobs are system daemons;
- both jobs start during boot;
- both jobs have the expected restart policy;
- the target SSID has the exact Unicode value `Schrödinger’s WiFi`;
- no credential value appears in evaluation output or a store path.

Run the flake evaluation and Darwin activation check before a switch. Use the repository's existing `turing` flake output unless a separate host-rename design is approved.

### Service tests

After activation, confirm:

- `pmset -g custom` disables computer sleep for battery and AC power;
- `pmset -g assertions` reports the managed idle-sleep assertion;
- launchd reports both jobs as loaded;
- the Wi-Fi watchdog status is readable by root;
- recent logs contain no secret or unrelated SSID.

Command-line status tools cannot prove the active SSID on this host because macOS redacts that value. Prove the final network identity through the local System Settings Wi-Fi view or the target access point's client list. Inspect only the connected target. Do not capture or list unrelated networks.

Terminate the managed sleep-assertion process. Confirm that launchd starts a replacement and the assertion returns.

Terminate the watchdog process. Confirm that launchd starts a replacement and performs an immediate health check.

### Idle observation

Leave Eisenhower idle with the lid open during an agreed observation period. Test on battery power and AC power.

Confirm that the power log has no system-sleep transition during either interval. Display power changes do not fail this test.

### Reboot test

Use a local console or a secondary management route.

After reboot, confirm:

- the sleep policy is active before user login;
- the sleep assertion job is running;
- the Wi-Fi watchdog is loaded;
- a Wi-Fi health check occurred during boot;
- Eisenhower connects to the exact target SSID without interactive input.

### Forced radio disconnect

Install an independent timed failsafe that turns the Wi-Fi radio on. Then turn the radio off.

Confirm that the watchdog:

1. records `radio_disabled`;
2. enables the radio;
3. attempts association;
4. reports `healthy` after recovery.

Do not run this test through the only Wi-Fi SSH route.

### Network-service interruption

Install the same independent failsafe. Disable the Wi-Fi network service and then restore it.

Confirm that the watchdog identifies the disabled service, enables it, and reconnects without user login.

### Forced disassociation

Disconnect Eisenhower from the access point without changing the credential.

Confirm that a new association attempt starts within five seconds and that the failure counter resets after recovery.

### Access-point outage and recovery

Turn off the target access point while the watchdog records events.

Confirm that:

- the watchdog classifies the failure without logging other network names;
- retry delays follow `5, 10, 20, 40, 60, 120, 300` seconds;
- later delays remain at 300 seconds;
- the watchdog does not stop retrying.

Restore the access point during the maximum backoff period. Confirm recovery within 300 seconds plus association time.

### Authentication failure and recovery

Run this test under local supervision. Use a temporary root-owned test credential with a known incorrect value. Do not print or store the value in logs.

Confirm that:

- the watchdog reports `authentication_failed`;
- retries follow the bounded backoff;
- the process list and logs contain no credential;
- restoring the valid credential and restarting the watchdog causes an immediate attempt;
- a successful attempt resets the failure count.

### Secret-safety audit

Search the evaluated configuration, generated launchd files, Nix store references, process arguments, unified logs, and status file for the credential value through a non-printing comparison.

The test passes only if no match exists. The audit must not print the searched value.

## Rollout and rollback

Before activation:

1. Record the current Darwin generation.
2. Build and check the new generation.
3. Confirm local console or secondary network access.
4. Keep the existing manual sleep daemons active.
5. Install an independent Wi-Fi recovery failsafe before disruptive tests.

If activation causes a problem:

1. Switch to the previous Darwin generation with the supported rollback command.
2. Stop and unload the new Wi-Fi watchdog.
3. Restore the Wi-Fi radio and network service.
4. Keep the existing manual sleep daemons active.
5. Preserve the credential file for diagnosis. Do not delete it automatically.

Remove the two old sleep daemons only in a later activation after all reboot, sleep, and connection-recovery tests pass.

## Acceptance criteria

The design is successfully implemented only when:

- configuration evaluation and Darwin checks pass;
- computer sleep is disabled on battery and AC power;
- the managed idle-sleep assertion survives process failure and reboot;
- Eisenhower connects to `Schrödinger’s WiFi` after boot without user login;
- radio, service, disassociation, access-point, and authentication tests recover as specified;
- repeated failures use bounded backoff and never stop permanently;
- logs and status provide enough evidence to diagnose failures;
- no password or unrelated SSID enters configuration, process arguments, logs, or status;
- rollback to the previous Darwin generation is verified.
