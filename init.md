# 🛸 Project Nebula: The Atomic NixOS Manifesto

## 1. Vision Statement
To architect a **Zero-Trust, Immutable, and Hardware-Agnostic Workstation** that separates the stable system core from experimental user-land configurations. The system shall prioritize FOSS purity on the host, delegating proprietary or "dirty" applications to isolated, declarative container environments.

## 2. Core Architectural Pillars
*   **Modular Agnosticism:** Use `flake-parts` to eliminate boilerplate and `nixos-facter` to decouple hardware specifics from system logic.
*   **Impermanence by Design:** Wipe the root filesystem (`/`) on every boot using Btrfs subvolumes to eliminate configuration drift.
*   **Pragmatic Persistence:** Temporarily preserve `/var` and `/home` as stateful subvolumes, incrementally migrating critical state to explicit `environment.persistence` blocks.
*   **Container-First Workflow:** 
    *   **Podman + Quadlet-Nix:** Replace Docker with daemonless, rootless systemd-integrated containers.
    *   **Systemd-nspawn (NixOS Containers):** Main engine for complex Linux environments (systemd-nspawn).
    *   **MicroVM:** For high-isolation or alternative kernel testing.
    *   **nix-flatpak:** User-level management of sandboxed GUI applications.
*   **Atomic Home Manager:** Run Home Manager in "Standalone" mode (not as a NixOS module) to ensure user-land breakage never prevents a system boot.

## 3. The Technical Stack
| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Flake Framework** | `flake-parts` | Module organization and input management. |
| **Hardware Layer** | `nixos-facter` | Declarative hardware profiles (JSON/Nix). |
| **Disk Management** | `disko` | Declarative Btrfs partitioning and subvolumes. |
| **State Control** | `impermanence` | Bind-mounting persistent state to a volatile root. |
| **Secret Management** | `sops-nix` / `agenix` | Encrypted secrets (SSH/GPG keys) via age. |
| **CLI & Debugging** | `lix` | Modern Nix fork for superior error reporting. |
| **Binary Compatibility**| `nix-ld` + `envfs` | Running unpatched binaries inside containers. |
| **Caching** | `cachix` | Custom binary caches to reduce local build times. |

## 4. Planned Directory Structure
```text
.
├── flake.nix               # Entry point (flake-parts)
├── parts/                  # flake-parts modules
├── hardware/               # nixos-facter profiles
├── modules/
│   ├── core/               # Boot, Disko, Impermanence, Sops
│   ├── hardware/           # GPU (Nvidia/Intel), CPU logic
│   ├── networking/         # Centralized Bridge (br0), Firewall
│   ├── containers/         # Podman/Quadlet, nspawn, MicroVM
│   └── desktop/            # Niri, Hyprland, Portals, Fonts
├── users/
│   └── addy/               # Standalone Home Manager
│       ├── apps/           # CLI/GUI tools
│       └── dotfiles/       # NVChad, Ghostty, Shells
└── outputs/                # Final nixosConfigurations & homeConfigurations
```

## 5. Critical Implementation Rules (The "Don't Break It" List)
1.  **The SSH Persistence Trap:** You **MUST** persist `/etc/ssh` before enabling `sops-nix`. If SSH keys are wiped, secrets cannot be decrypted, and the boot will hang.
2.  **The `stateVersion` Law:** Never set `stateVersion` to a future/unreleased version. Keep it at the version of initial installation (e.g., `25.11`) to prevent stateful migration errors.
3.  **Networking Zen:** Do not let container engines manage NAT. Create a single `br0` bridge in NixOS and point all containers/VMs to it to avoid `nftables` conflicts.
4.  **Locale Hygiene:** Set `i18n.defaultLocale`. **NEVER** set `LC_ALL` globally; it is a debug override that breaks scripts.
5.  **Subvolume Exclusion:** Exclude `/var/lib/containers` and `/var/lib/flatpak` from automated Btrfs snapshots to prevent massive storage bloat from image caches.

## 6. Legacy Logic to Port (Salvage List)
*   **The `no-gpu` Specialization:** Port the `udev` PCI-removal logic into `modules/hardware/nvidia.nix`.
*   **PRIME Offload:** Port the Intel/Nvidia Bus ID configuration.
*   **Gaming Stack:** Keep the `steam` and `heroic` (with gamescope/gamemode) overrides.
*   **Modern Fonts:** Port the JetBrains/Fira/Iosevka Nerd Font selections.

## 7. Development Roadmap
*   **Phase 1:** Core Boot. Disko + Impermanence + Basic Networking. (Verify via VM).
*   **Phase 2:** Secrets. Sops-nix + SSH Persistence. (Verify decryption).
*   **Phase 3:** Hardware. Facter integration + GPU Profiles.
*   **Phase 4:** Containers. Quadlet + nspawn + MicroVM setup.
*   **Phase 5:** Desktop. Niri/Hyprland + Home Manager Standalone.

---
*Context initialized for future AI assistance. Ready for implementation.*
