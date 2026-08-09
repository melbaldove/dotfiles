# Eisenhower Sleep and Wi-Fi Recovery Design

Date: 2026-08-09

Status: Revised design pending final written-spec review

## Purpose

This design makes the existing macOS host Eisenhower a nix-darwin-managed host and makes it resilient during normal operation.

It has two required properties:

1. Eisenhower does not enter system sleep because of idle time.
2. Eisenhower continuously tries to connect to the exact Wi-Fi SSID `Schrödinger’s WiFi`.

This document defines the design and its verification. It does not authorize implementation.

## Source evidence

The `.dotfiles` repository currently manages Turing as one machine:

- The flake exposes `darwinConfigurations.turing`.
- The host module declares `networking.hostName = "turing"`.

Eisenhower is a separate machine. The live Eisenhower host identifies as `eisenhower.local`, but `.dotfiles` does not yet contain an Eisenhower host assembly or Darwin output.

The `nix-infra` input is declared in `.dotfiles`. The current Darwin assembly does not use it. Eisenhower does not need that input unless implementation discovers a specific shared dependency.

The evaluated Darwin configuration does not declare a sleep policy. Each `power.sleep.*` value is `null`.

The live host has these unmanaged controls:

- `pmset` reports `sleep = 0` for battery and AC power.
- `com.local.nosleep` applies idle-sleep, display-sleep, and disk-sleep values at load time.
- `com.aura.caffeinate` runs `caffeinate -s` with `KeepAlive`.

The live host has no Wi-Fi recovery job. Its Wi-Fi metadata has exactly one user-preferred network identity: `Schrödinger’s WiFi`.

Darwin secret management is manual. The Darwin module installs `agenix`, but it does not declare or materialize secrets. The expected repository `secrets/` directory is not present in this checkout.

The repository has existing user changes in `codex/AGENTS.md`, `flake.lock`, and `hosts/turing/default.nix`. Future work must preserve those changes.

## Repository ownership decision

### Considered layout: all Eisenhower configuration in `nix-infra`

In this layout, `nix-infra` owns the Eisenhower host assembly, Darwin system modules, connectivity jobs, and system activation. It consumes `.dotfiles` only for Home Manager user configuration.

This layout gives one infrastructure repository for all machine assemblies and could reuse the established agenix inventory. It does not match the current flake structure. `nix-infra` defines NixOS server configurations, NixOS modules, deploy-rs nodes, and NixOS deployment checks. It has no nix-darwin input, Darwin output, or Darwin deployment path. Its documented deployment command runs deploy-rs from Einstein. Adding Eisenhower would require a second operating-system toolchain and a separate activation path in the server repository.

This layout also increases flake coupling. `nix-infra` already consumes `.dotfiles` for user configuration, while `.dotfiles` currently declares `nix-infra` as an input. Making `nix-infra` the Darwin assembly owner would make the dependency boundary harder to understand and test.

### Considered layout: shared Darwin modules in `.dotfiles`, host assembly in `nix-infra`

In this layout, `.dotfiles` exports reusable Darwin modules and Home Manager profiles. `nix-infra` defines `darwinConfigurations.eisenhower` and imports those modules.

This creates a clear module-versus-host distinction in theory. It does not give the smallest practical boundary for the current repositories. The Darwin defaults, GUI settings, Homebrew integration, host packages, Home Manager assembly, and Darwin activation history already live together in `.dotfiles`. Splitting the assembly would require synchronized changes and revisions across both repositories for one host. Evaluation, activation, and rollback would depend on two repository revisions.

This layout also creates a decision problem for host-specific launchd jobs. Putting them in `.dotfiles` makes `nix-infra` a thin wrapper. Putting them in `nix-infra` splits Darwin system ownership across repositories.

### Selected layout: all Eisenhower nix-darwin configuration in `.dotfiles`

`.dotfiles` is the sole source of truth for Eisenhower.

It owns:

- `darwinConfigurations.eisenhower`;
- the Eisenhower host assembly;
- Darwin system and launchd modules;
- Home Manager user imports;
- the declared SSID identity;
- configuration evaluation;
- local activation;
- Darwin generation rollback;
- Eisenhower-specific verification documentation.

`nix-infra` remains unchanged. It continues to own NixOS server configurations, deploy-rs nodes, infrastructure services, and server-side agenix secrets. It can continue to consume published `.dotfiles` user modules for Linux hosts. It does not assemble, activate, or roll back Eisenhower.

This layout matches the existing repository purposes and commands. `.dotfiles` already contains the nix-darwin input, the existing Turing Darwin host, shared Darwin modules, Home Manager profiles, and the documented `darwin-rebuild` workflow. Each Darwin host generation can be built, activated, and rolled back from one repository revision.

The Wi-Fi credential is not owned by either Git repository. macOS owns it in the System Keychain as part of the preferred-network configuration. A user provisions it separately through System Settings or another explicit interactive setup. This boundary prevents the server-secret inventory in `nix-infra` from becoming an indirect runtime dependency of the Mac.

## Nix-darwin host boundary

Turing and Eisenhower remain separate host assemblies. Turing is not renamed, moved, or used as an Eisenhower template without module-by-module review.

The final assembly has these ownership rules:

- `flake.nix` keeps `darwinConfigurations.turing` mapped to `hosts/turing/default.nix`.
- `flake.nix` adds `darwinConfigurations.eisenhower` mapped to `hosts/eisenhower/default.nix`.
- `hosts/eisenhower/default.nix` is the Eisenhower assembly root.
- `hosts/turing/default.nix` remains the Turing assembly root and keeps its current behavior.
- Eisenhower reuses only modules under `modules/system/darwin/` that evaluation and review prove to be machine-independent.
- Eisenhower reuses the existing Home Manager profiles under `users/melbournebaldove/` because they describe the same user, subject to host evaluation.
- Eisenhower-only sleep and connectivity logic remains under `hosts/eisenhower/` unless a second proven reuse case exists.
- Turing does not import Eisenhower-specific sleep or Wi-Fi recovery logic.
- Neither host assembly imports the other host assembly.

The implementation must preserve `hosts/turing/default.nix` and its current uncommitted changes unchanged. Adding Eisenhower must not require a Turing rebuild or activation.

### Activation and rollback commands

All Eisenhower lifecycle commands run from `.dotfiles` on Eisenhower.

- Check: `sudo darwin-rebuild check --flake .#eisenhower`
- Activate: `sudo darwin-rebuild switch --flake .#eisenhower`
- List generations: `darwin-rebuild --list-generations`
- Roll back: `sudo darwin-rebuild switch --rollback`

`nix-infra` deploy-rs commands do not target Eisenhower.

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
- Changes to `nix-infra`.
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
- `credential_unavailable`: the exact target is not a usable preferred network or macOS has no usable System Keychain credential for it.
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

macOS preferred-network configuration and the System Keychain are the only credential boundary. A user provisions `Schrödinger’s WiFi` interactively through System Settings or another explicit interactive setup. The watchdog does not create, read, export, copy, decrypt, rotate, or delete the credential.

Before an association attempt, the watchdog confirms that the exact target exists as a preferred-network identity. It does this without listing or logging other preferred or nearby networks.

The watchdog invokes `/usr/sbin/networksetup -setairportnetwork <device> 'Schrödinger’s WiFi'`. The command has no password argument. The watchdog also supplies no password through standard input, an environment variable, or a file path. macOS resolves the saved credential through its native preferred-network and System Keychain behavior.

If the exact target is not preferred, the watchdog records `credential_unavailable`, does not attempt password-based association, and continues bounded checks. If a password-free association attempt fails because macOS cannot use the saved credential, the watchdog records `authentication_failed`. Both states require manual credential provisioning or correction. The watchdog never tries to repair a credential.

## Observability

The watchdog writes structured, sanitized events to the macOS unified log.

Each event can contain:

- component name;
- state;
- attempt number;
- next retry delay;
- result class;
- last successful association time.

The watchdog also writes an atomic, root-owned status file at `/var/db/eisenhower/wifi-watchdog.status`. The status file contains the current state, failure count, retry delay, and timestamps.

Logs and status must not contain:

- the Wi-Fi password;
- BSSID values;
- unrelated SSIDs;
- nearby network lists;
- Keychain output or credential metadata other than the exact target identity and a usable-or-unavailable result.

## Verification

### Configuration evaluation

Evaluate the Darwin configuration and confirm:

- computer sleep evaluates to `never`;
- power-button sleep evaluates to disabled;
- both launchd jobs are system daemons;
- both jobs start during boot;
- both jobs have the expected restart policy;
- the target SSID has the exact Unicode value `Schrödinger’s WiFi`;
- no credential file is declared or created;
- no Keychain secret extraction command exists;
- the association command has no password argument, password environment variable, or password input path.

Run the flake evaluation and Darwin activation check from `.dotfiles` before a switch. Use the canonical `eisenhower` flake output.

### Service tests

After activation, confirm:

- `pmset -g custom` disables computer sleep for battery and AC power;
- `pmset -g assertions` reports the managed idle-sleep assertion;
- launchd reports both jobs as loaded;
- the Wi-Fi watchdog status is readable by root;
- recent logs contain no secret or unrelated SSID.

Confirm that the exact target is present in the preferred-network configuration without printing unrelated preferred networks. Then inspect the running association attempt and confirm that its arguments contain only the executable, Wi-Fi device, and exact target SSID. A successful association must occur without a password argument or interactive prompt.

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

### Authentication failure and manual recovery

Use the watchdog command adapter to return a controlled, sanitized authentication failure. This test does not alter, extract, replace, or delete the live System Keychain credential.

Confirm that:

- the watchdog reports `authentication_failed`;
- retries follow the bounded backoff;
- no credential file is created;
- the process list and logs contain no password or Keychain output;
- the watchdog does not invoke a Keychain extraction command;
- the watchdog requires manual credential provisioning after a real credential failure.

For live recovery proof, first confirm the target is preferred. Then use the credential already provisioned interactively and restart the watchdog for an immediate password-free association attempt. A successful attempt resets the failure count. If the credential is unusable, stop the test and provision it manually through System Settings before retrying.

### Secret-safety audit

Inspect the evaluated configuration, generated launchd files, Nix store references, process arguments, environment, unified logs, status file, and Eisenhower service-state paths.

The test passes only if:

- no service credential file exists;
- no configuration or script reads a Keychain secret;
- no association command includes a password argument;
- no password environment variable or standard-input path exists;
- no log or status output contains Keychain output or a credential value.

The audit must not extract or print the System Keychain password.

## Rollout and rollback

Before activation:

1. Record the current Darwin generation.
2. Build and check the new `.dotfiles#eisenhower` generation.
3. Confirm local console or secondary network access.
4. Keep the existing manual sleep daemons active.
5. Install an independent Wi-Fi recovery failsafe before disruptive tests.

If activation causes a problem:

1. Switch to the previous Darwin generation with the supported rollback command.
2. Stop and unload the new Wi-Fi watchdog.
3. Restore the Wi-Fi radio and network service.
4. Keep the existing manual sleep daemons active.
5. Leave the preferred-network and System Keychain configuration unchanged.

Remove the two old sleep daemons only in a later activation after all reboot, sleep, and connection-recovery tests pass.

Rollback uses the Darwin generation history created by `.dotfiles`. It does not use deploy-rs or a `nix-infra` revision.

## Acceptance criteria

The design is successfully implemented only when:

- configuration evaluation and Darwin checks pass;
- `.dotfiles` contains one Eisenhower host assembly and one canonical Eisenhower Darwin output;
- `darwinConfigurations.turing` and `hosts/turing/default.nix` remain intact and separate from Eisenhower;
- `nix-infra` remains unchanged and is not required for Eisenhower activation or rollback;
- computer sleep is disabled on battery and AC power;
- the managed idle-sleep assertion survives process failure and reboot;
- Eisenhower connects to `Schrödinger’s WiFi` after boot without user login;
- radio, service, disassociation, access-point, and authentication-state tests behave as specified;
- repeated failures use bounded backoff and never stop permanently;
- logs and status provide enough evidence to diagnose failures;
- no service credential file is created;
- association succeeds through the native preferred-network credential without a password argument;
- no password or unrelated SSID enters configuration, process arguments, environment, logs, or status;
- rollback to the previous Darwin generation is verified.
