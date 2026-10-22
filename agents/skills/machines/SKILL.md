---
name: machines
description: Use before you run work on another of the user's machines (Turing, Eisenhower, Einstein), or when you plan heavy, long, architecture-specific, GPU, or Xcode work. Gives each machine's hardware, role, and services to leave alone, and how to run work there.
---

# Machines

The user has three machines on one Tailscale network. Run `hostname` to learn which one you are on. From any of them, `ssh einstein`, `ssh eisenhower`, and `ssh turing` reach the others, and `sudo` needs no password. Turing can be asleep or off the network, so work on a server must not depend on reaching it.

| Machine | Role | Hardware | Platform and tools | Services to leave alone |
|---|---|---|---|---|
| Turing | The user's daily laptop. It can be on battery, asleep, or off the network. | MacBook Air, Apple M4, 10 cores (4 performance), 24 GB unified memory, no fan. Its 461 GB disk is often almost full. | `aarch64-darwin` (Apple silicon, macOS). Xcode. OrbStack Docker engine (arm64). | None. |
| Eisenhower | Always-on Mac server. It does not sleep and stays on AC power. | MacBook Pro, Apple M1 Pro, 10 cores (8 performance), 16-core GPU, 16 GB unified memory, 461 GB disk. | `aarch64-darwin` (Apple silicon, macOS). Xcode. Docker CLI only, with no Docker engine. | OptMem store, Hey You iOS GitHub Actions runner, Oi (hy-agents), T3 Code server. |
| Einstein | Always-on Linux server. | AMD Ryzen 7 3800XT, 8 cores and 16 threads, 16 GB RAM, NVIDIA RTX 2070 SUPER with 8 GB VRAM, 1 TB NVMe disk and a 1 TB media disk. | `x86_64-linux` (NixOS). Docker engine (amd64). NVIDIA driver (`nvidia-smi`). There is no apt; use `nix shell nixpkgs#<package>` for a one-off tool. | Docker, nginx, nix-serve cache, Jellyfin, qBittorrent, OptMem backups, T3 Code server. |

## Choose a machine

- Choose the machine for a piece of work by what the work needs, because the machines differ in architecture, hardware, and availability. The table gives capacity, not current state. Before you start heavy work on a machine, check its load, free memory, and free disk, for example with `uptime`, `df -h`, and on Einstein `nvidia-smi`.
- Build and test on the architecture where the result will run. Do x86_64 Linux work, such as amd64 container images, x86_64 Lambda packages, and `x86_64-linux` Nix builds, on Einstein, because a Mac runs it under emulation, which is slow and can fail in different ways. Do macOS and iOS work, such as Xcode builds, simulators, Swift, and Metal, on a Mac.
- Use Einstein for CUDA work. Its GPU has 8 GB of VRAM, so large models do not fit. For local models on Apple silicon, Turing has the most unified memory, but it is the user's laptop.
- Move long or heavy jobs, such as large builds, full test suites, data processing, and long agent runs, off Turing when another machine can do them, because Turing has no fan, can sleep or leave the network, has little free disk, and heavy work there slows the user's own work. From a server, send work to Turing only when it needs something only Turing has, such as 24 GB of unified memory or an arm64 Docker engine.
- Do not start, stop, restart, or starve the services in the table unless the task is about them. Eisenhower has only 16 GB of memory and also runs iOS CI, so check its load before you add heavy work there.

## Run work on another machine

- Move work only when the gain is larger than the cost of the move. The other machines do not share your working tree: push a branch or copy the files, run the job, and bring the results back. Uncommitted edits do not move with you. Tools and sign-ins, such as cloud credentials, can differ between machines, so check them before you depend on them.
- Run a long job on a remote machine inside `tmux`, so that a dropped SSH session does not stop it.
