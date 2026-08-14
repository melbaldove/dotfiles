# Eisenhower Sleep and Wi-Fi Recovery Design

Date: 2026-08-09

Last revised: 2026-08-15

Status: Native-first recovery correction pending final written-spec review

## Purpose

This design makes the existing macOS host Eisenhower a nix-darwin-managed host and makes it resilient during normal operation.

It has two required properties:

1. Eisenhower does not enter system sleep because of idle time.
2. Eisenhower continuously tries to connect to the exact Wi-Fi SSID `Schrödinger’s WiFi`.

This document defines the design and its verification. It does not authorize implementation.

## Source evidence

The `.dotfiles` repository manages Turing and Eisenhower as separate machines:

- The flake exposes `darwinConfigurations.turing`.
- The flake exposes `darwinConfigurations.eisenhower`.
- Each output has its own host assembly under `hosts/`.

The live Eisenhower host identifies as `eisenhower`. Its active nix-darwin configuration includes the managed sleep controls and Wi-Fi watchdog. Turing remains a separate host and is not part of the Eisenhower activation path.

The `nix-infra` input is declared in `.dotfiles`. The current Darwin assembly does not use it. Eisenhower does not need that input unless implementation discovers a specific shared dependency.

The managed power policy sets computer sleep to `0` for battery and AC power. The managed `com.eisenhower.prevent-idle-sleep` daemon holds the runtime idle-sleep assertion.

The live Wi-Fi metadata includes the preferred network identity `Schrödinger’s WiFi`. Auto-Join is enabled, and a manual selection connects without a password prompt. The credential is therefore valid, but that fact alone does not prove autonomous recovery.

On 2026-08-14, Eisenhower remained awake but disconnected for approximately 17 hours. The watchdog completed 203 unsuccessful recovery cycles. A manual selection restored the connection immediately.

The macOS unified log gives this failure sequence:

1. At `06:41:52`, the link went down and native Auto-Join started.
2. At `06:42:04`, the watchdog's `networksetup` request started a competing join.
3. macOS disabled Auto-Join while that join was active.
4. The competing join failed with internal result `-3900`, disassociated the interface, and caused macOS to blocklist the known network.
5. Later watchdog requests did not clear the blocklist. Manual selection recovered the connection.

The saved profile records `wpa3-transition`, while the access points can advertise `wpa2-personal`. That combination is not sufficient to explain the outage because it also appeared during successful recovery.

Two controlled 2026-08-15 tests paused the watchdog, cycled the radio, and observed native Auto-Join. Native recovery restored the approved IP, gateway, DNS, HTTPS, and SSH contract in five seconds both while the screen was unlocked and while it was locked. Lock state is not the failure cause. The important difference is the competing watchdog association request.

Darwin secret management is manual. The Darwin module installs `agenix`, but it does not declare or materialize secrets. The expected repository `secrets/` directory is not present in this checkout.

The repository has existing user changes in `claude/settings.json`, `codex/AGENTS.md`, `flake.lock`, and `hosts/turing/default.nix`. Future work must preserve those changes.

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

### Native Auto-Join only

This approach uses nix-darwin sleep settings and only the native macOS preferred-network behavior.

It has a small configuration surface. It does not give controlled retry timing, durable failure evidence, or a direct way to test repeated authentication failures.

### Native-first recovery guardian

This approach uses nix-darwin for the sleep policy and two system launch daemons for live enforcement and Wi-Fi recovery. Native Auto-Join is the only association owner. The root watchdog restores the Wi-Fi service or radio, gives native Auto-Join time to operate, validates recovery, and uses a bounded radio cycle when recovery stalls.

It gives reproducible configuration, continuous recovery opportunities, bounded backoff, sanitized evidence, and independent process recovery. It does not compete with macOS association or handle the password.

This is the approved approach.

### Native grace followed by direct association

This approach keeps `/usr/sbin/networksetup -setairportnetwork` after a native Auto-Join grace period. It keeps an explicit target request, but it can reproduce the observed competing-join and blocklist failure. The design rejects this approach.

### User LaunchAgent association

This approach moves the direct association request into the logged-in user session. It adds root-to-user coordination, does not operate before the first login, and has no proven advantage over native Auto-Join. The design rejects this approach.

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

Native macOS Auto-Join is the only association owner. The watchdog must not invoke `networksetup -setairportnetwork`, call a private Wi-Fi association API, or start a second association while macOS is already recovering.

The watchdog uses two health layers:

- The network-identity layer requires IPv4 `192.168.50.140/24`, gateway `192.168.50.1`, a default route on the Wi-Fi device, and local SSH management reachability.
- The online-service layer checks DNS and HTTPS separately.

The live host redacts its active SSID from command-line status tools, including privileged status calls. When the complete approved network contract is healthy, the watchdog accepts that operational identity without requiring visible SSID output. It does not accept an arbitrary address, subnet, gateway, or route. When the SSID is observable, it must be the exact UTF-8 value `Schrödinger’s WiFi`.

For each healthy check, the watchdog records the result and waits 30 seconds before the next check. It does not reassert the SSID and does not issue a redundant association request.

For each unhealthy transition, it:

1. Finds the Wi-Fi device and service.
2. Confirms that the exact target remains a preferred network without printing unrelated preferred networks.
3. Enables the network service if it is disabled, then gives native Auto-Join 30 seconds to recover.
4. Enables the Wi-Fi radio if it is disabled, then gives native Auto-Join 30 seconds to recover.
5. If the service and radio were already enabled, gives the existing native Auto-Join attempt 30 seconds to finish.
6. If the network-identity layer is still unhealthy, cycles the Wi-Fi radio once and gives native Auto-Join another 30 seconds to recover.
7. Records the failed contract component and a sanitized retry result.

If the network-identity layer is healthy but DNS or HTTPS fails, the watchdog records the online-service failure. It does not cycle the radio because an upstream service failure is not proof of lost Wi-Fi association.

After an unsuccessful recovery cycle, the watchdog retries after these delays:

`60, 120, 300` seconds.

The delay remains at 300 seconds after later failures. The watchdog never enters a terminal failure state. A healthy network contract resets the failure count and delay.

launchd restarts the watchdog if its process exits. A process restart causes one immediate health check. launchd throttling prevents a crash loop.

## Wi-Fi state model

The watchdog uses these states:

- `interface_missing`: macOS does not report a Wi-Fi hardware port.
- `preferred_target_unavailable`: the exact target is not present as a preferred network identity.
- `service_disabled`: the Wi-Fi network service is disabled.
- `radio_disabled`: the Wi-Fi radio is disabled.
- `native_autojoin_wait`: the watchdog is allowing native Auto-Join to finish without interference.
- `radio_cycle`: the watchdog is creating a new native Auto-Join opportunity after the initial grace period.
- `address_failed`: the expected IPv4 address or subnet is absent.
- `route_failed`: the expected gateway or default route is absent.
- `management_failed`: local SSH management reachability failed.
- `dns_failed`: DNS resolution failed after the network-identity layer passed.
- `https_failed`: the approved HTTPS check failed after the network-identity layer passed.
- `native_recovery_failed`: the network-identity layer remains unhealthy after the bounded native recovery sequence.
- `command_failed`: a required system command fails for another reason.
- `healthy`: the complete approved network contract passes.

The watchdog does not infer an authentication error from `networksetup` output because it no longer starts an association. Native macOS diagnostics can report authentication, security-suite, blocklist, or access-point failures during incident analysis, but those details are not stable control inputs for the daemon.

## Credential boundary

The Wi-Fi password must not enter:

- the Git repository;
- the Nix store;
- the generated launchd property list;
- a process argument;
- the unified log;
- the watchdog status file.

macOS preferred-network configuration and the System Keychain are the only credential boundary. A user provisions `Schrödinger’s WiFi` interactively through System Settings or another explicit interactive setup. The watchdog does not create, read, export, copy, decrypt, rotate, or delete the credential.

Before a recovery action, the watchdog confirms that the exact target exists as a preferred-network identity. It does this without listing or logging other preferred or nearby networks.

The watchdog does not supply an SSID or password to an association command. It restores supported service and radio state, then lets native Auto-Join use the preferred-network and System Keychain configuration.

If the exact target is not preferred, the watchdog records `preferred_target_unavailable`, does not change credentials, and continues bounded checks. Manual System Settings work is required to add, correct, or rotate the credential. The watchdog never tries to repair a credential or clear a macOS network blocklist through private interfaces.

## Observability

The watchdog writes structured, sanitized events to the macOS unified log.

Each event can contain:

- component name;
- state;
- attempt number;
- recovery trigger;
- failed contract component;
- next retry delay;
- result class;
- last healthy-contract time.

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
- the UTF-8 target value has SHA-256 `8e7be252173ea3d0905dda6be969e5cf6f3daf3924759227695d8fbd5d200a3d`;
- no credential file is declared or created;
- no Keychain secret extraction command exists;
- no command invokes `networksetup -setairportnetwork`;
- no private Wi-Fi association command or API exists;
- no password argument, password environment variable, or password input path exists;
- the native grace period, radio-cycle bound, and retry sequence are exact.

Run the flake evaluation and Darwin activation check from `.dotfiles` before a switch. Use the canonical `eisenhower` flake output.

### Watchdog regression tests

The command adapter can simulate service, radio, address, route, DNS, HTTPS, and management state. It must not make an association command create a healthy address or route. Test code changes network health only through an explicit external fixture transition.

The regression suite must prove:

- a healthy contract causes no recovery action;
- a healthy contract with redacted SSID output causes no recovery action;
- a wrong address, subnet, gateway, or route is rejected;
- a link-down event gets the full native Auto-Join grace period;
- service restoration occurs before native recovery wait;
- radio restoration occurs before native recovery wait;
- a stalled native recovery causes one bounded radio cycle;
- later failures use `60, 120, 300` second backoff;
- success resets the failure count and backoff;
- repeated healthy checks are idempotent;
- process arguments and logs contain no credential;
- no test or production path invokes `networksetup -setairportnetwork`.

### Service tests

After activation, confirm:

- `pmset -g custom` disables computer sleep for battery and AC power;
- `pmset -g assertions` reports the managed idle-sleep assertion;
- launchd reports both jobs as loaded;
- the Wi-Fi watchdog status is readable by root;
- recent logs contain no secret or unrelated SSID.

Confirm that the exact target is present in the preferred-network configuration without printing unrelated preferred networks. Confirm that Auto-Join is enabled for the exact target. Inspect the watchdog process and logs and confirm that it does not start an association command. Native macOS Auto-Join must recover without a password argument or interactive prompt.

Command-line status tools cannot prove the active SSID on this host because macOS redacts that value. Prove the final network identity through the local System Settings Wi-Fi view or the target access point's client list. Inspect only the connected target. Do not capture or list unrelated networks.

Terminate the managed sleep-assertion process. Confirm that launchd starts a replacement and the assertion returns.

Terminate the watchdog process. Confirm that launchd starts a replacement and performs an immediate health check.

The service test passes only when the watchdog log and macOS Wi-Fi log identify the responsible mechanism. Final connectivity without a causal event sequence is not sufficient proof.

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
- no direct association command ran;
- Eisenhower connects to the exact target SSID without interactive input.

### Forced radio disconnect

Install an independent timed failsafe that turns the Wi-Fi radio on. Then turn the radio off.

Confirm that the watchdog:

1. records `radio_disabled`;
2. enables the radio;
3. records `native_autojoin_wait`;
4. does not run `networksetup -setairportnetwork`;
5. reports `healthy` after native recovery.

Do not run this test through the only Wi-Fi SSH route.

Run the radio test once while the screen is unlocked and once while it is locked. For each run, capture the macOS native Auto-Join start and success events. A password-free manual selection is not an automatic-recovery pass.

### Network-service interruption

Install the same independent failsafe. Disable the Wi-Fi network service and then restore it.

Confirm that the watchdog identifies the disabled service, enables it, gives native Auto-Join the full grace period, and reconnects without user login or a direct association command.

### Forced disassociation

Disconnect Eisenhower from the access point without changing the credential.

Confirm that native Auto-Join starts without a competing watchdog join. The watchdog must record `native_autojoin_wait`, must not call `networksetup -setairportnetwork`, and must reset the failure counter after the approved network contract recovers.

### Access-point outage and recovery

Turn off the target access point while the watchdog records events.

Confirm that:

- the watchdog classifies the failure without logging other network names;
- the initial native grace period completes before a radio cycle;
- each radio cycle creates one native Auto-Join opportunity;
- retry delays follow `60, 120, 300` seconds;
- later delays remain at 300 seconds;
- the watchdog does not stop retrying.

Restore the access point during the maximum backoff period. Confirm native recovery within 330 seconds: the maximum 300-second retry delay plus the 30-second recovery window. Confirm that no direct association command ran.

### Native failure and manual recovery

Use sanitized test fixtures for the observed native failure sequence: competing join, result `-3900`, disassociation, and known-network blocklist. The regression must prove that the corrected watchdog does not issue the competing association request.

Confirm that:

- the watchdog waits for native Auto-Join;
- one failed native recovery increments the bounded retry counter;
- the watchdog uses only service restoration or a bounded radio cycle;
- no credential file is created;
- the process list and logs contain no password or Keychain output;
- the watchdog does not invoke a Keychain extraction command or private blocklist operation;
- a real invalid credential still requires manual provisioning through System Settings.

Do not create a live invalid credential to test this state. A live test must use the existing preferred credential and must not read, replace, or delete it.

### Secret-safety audit

Inspect the evaluated configuration, generated launchd files, Nix store references, process arguments, environment, unified logs, status file, and Eisenhower service-state paths.

The test passes only if:

- no service credential file exists;
- no configuration or script reads a Keychain secret;
- no direct association command exists;
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
- radio, service, disassociation, access-point, and native-failure tests behave as specified;
- repeated failures use bounded backoff and never stop permanently;
- logs and status provide enough evidence to diagnose failures;
- no service credential file is created;
- native Auto-Join succeeds through the preferred-network credential without a password argument;
- the watchdog never issues a competing direct association command;
- locked-screen and unlocked-screen recovery both pass;
- verification identifies the responsible recovery mechanism instead of accepting final connectivity alone;
- no password or unrelated SSID enters configuration, process arguments, environment, logs, or status;
- rollback to the previous Darwin generation is verified.
