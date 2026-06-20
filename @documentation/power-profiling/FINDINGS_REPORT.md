# Findings Report: NixOS Laptop Overheating — Root Cause Analysis

> **Knowledge Organization**: This report layers findings from concrete (observed system state) to abstract (architectural explanations), following the hierarchical reasoning framework described in ReasonFlux (Huang et al., 2025). Each issue is cross-referenced with the hardware-theory directory for deeper background.

> **System**: NixOS 26.11, Linux 7.0.11, Intel i7-11800H (Tiger Lake), NVIDIA RTX 3070 Laptop GPU
> **Date**: 2026-06-16
> **Symptom**: Laptop regularly overheats under load

---

## Executive Summary

After thorough investigation of the NixOS configuration, running system state, and Linux power management subsystems, **three primary issues** and **two contributing issues** were identified as causing the overheating:

### Primary Root Causes

| # | Issue | Severity | Detail |
|---|---|---|---|
| 1 | **No thermald** | 🔴 Critical | Intel Thermal Daemon not installed, commented out at `modifications.nix:41` |
| 2 | **intel_pstate in passive mode** (no HWP) | 🟡 High | CPU scaling driver is `intel_cpufreq`, not `intel_pstate` active mode with HWP |
| 3 | **NVIDIA dGPU always on in P0 state** | 🟡 High | GPU loads at every boot, stays in P0, no automatic PCI removal on battery |

### Contributing Issues

| # | Issue | Severity | Detail |
|---|---|---|---|
| 4 | **All power config commented out** | 🟠 Medium | thermald, upower, governor, cachyos-tweaks — all intended but disabled |
| 5 | **linuxPackages_latest kernel** | 🔵 Low | Kernel 7.0.11 may have regressions; no LTS fallback available |

---

## Issue 1: No thermald (Critical)

### Location
`modifications.nix:41` — commented out: `# services.thermald.enable = true;`

### What thermald Does

`thermald` (Intel Thermal Daemon) is a userspace daemon that provides **proactive thermal management** for Intel CPUs. Its components:

1. **Temperature Monitoring**: Reads CPU Digital Thermal Sensors (DTS) via `/sys/class/thermal/` sysfs interface
2. **Cooling Device Management**: Controls available cooling methods — P-state limiting via cpufreq, power clamping via RAPL (Running Average Power Limit), and PowerClamp (software-controlled idle injection)
3. **Trip Point Configuration**: Sets temperature thresholds at which cooling actions are triggered
4. **ACPI Integration**: Parses ACPI thermal zones and can override buggy BIOS thermal tables

### What Runs Without thermald

Without `thermald`, only the kernel's built-in thermal protection is active:
- **Critical trip point** (~100°C for Tiger Lake): Kernel forces emergency throttling or shutdown
- **Passive trip point** (from ACPI DSDT): Typically at 85-95°C, triggers cpufreq throttling
- **PROCHOT** (Processor Hot, ~100°C): CPU hardware signal that forces immediate clock reduction

The key gap: **There is no management between normal operation (~40-60°C) and emergency throttling (~95°C)**. Under sustained load, the CPU can ramp to 90°C+ before any corrective action is taken, causing:
- Fan noise (fans spin at max speed belatedly)
- Thermal discomfort (chassis gets very hot)
- Potential performance throttling (when emergency measures finally kick in)
- Long-term thermal stress on components

### How thermald Fixes This

With `thermald` enabled, the daemon:
1. Reads DTS temperature every polling interval (default: adjustable, typically 1-5s)
2. If temperature exceeds a configurable target (default: varies by platform, typically ~75-85°C), engages cooling:
   - Writes to `intel_pstate/max_perf_pct` in sysfs to limit maximum P-state
   - Uses RAPL MSRs (MSR_PKG_POWER_LIMIT, MSR_DRAM_POWER_LIMIT) to set power caps
   - Uses PowerClamp (intel_powerclamp kernel module) for idle injection
3. Gradually relaxes cooling as temperature drops

### Configuration

```nix
services.thermald.enable = true;  # Add this to modifications.nix
```

No additional configuration is needed for basic operation — `thermald` runs in zero-configuration mode by default. For fine-tuning, `/etc/thermald/thermal-conf.xml` can be customized.

### Can Run With
- `power-profiles-daemon` ✓ (they manage different things)
- `tlp` ✓ (though they overlap on power limits)
- `auto-cpufreq` ✓ (though they overlap)
- `cachyos-tweaks.nix` ✓

### Cannot Run With
- Nothing — `thermald` is complementary to all other power management tools

---

## Issue 2: intel_pstate in Passive Mode (No HWP)

### Location
Global kernel state — no explicit config controls this; it's the kernel's detected behavior.

### What the Current State Is

```
scaling_driver: intel_cpufreq
intel_pstate/status: passive
ENERGY_PERFORMANCE_PREFERENCE: Not available
```

The CPU is using the `intel_cpufreq` driver, which is the **passive mode** of `intel_pstate`. In this mode:
- The Linux kernel's cpufreq subsystem selects the P-state
- Generic governors (`schedutil`, `powersave`, `performance`, etc.) are used
- `energy_performance_preference` (EPP) is not available
- The CPU's HWP (Hardware P-State) feature is NOT used

### What HWP Would Provide

Hardware P-States (HWP), introduced with Intel Haswell (4th gen) and significantly improved in Skylake (6th gen), allow the **CPU to manage its own P-states** based on hints from the OS. Key capabilities:

1. **Finer granularity**: HWP can change P-states every ~1ms (vs ~4ms tick rate for software governors)
2. **Better latency**: The hardware responds instantaneously to workload changes
3. **EPP (Energy Performance Preference)**: The OS provides a hint (0-255, or named: `performance`, `balance_performance`, `default`, `balance_power`, `power`) that biases the hardware's internal selection algorithm
4. **HWP interrupts**: The CPU can notify the OS when it reaches thermal limits
5. **Per-core P-states**: Each core can independently select its optimal P-state
6. **Package-level optimization**: The hardware can balance power across cores

### Why HWP Is Not Active

The Tiger Lake i7-11800H **should** support HWP. Possible reasons it's not active:

| Cause | Diagnosis | Fix |
|---|---|---|
| BIOS disabled HWP | Check BIOS settings for "Intel Speed Shift" or "HWP" | Enable in BIOS/UEFI setup |
| Kernel version regression | Linux 7.0.11 is very new | Try `linuxPackages_lts` or check kernel dmesg |
| BIOS doesn't advertise HWP via ACPI CPPC | `dmesg \| grep -i intel_pstate` | May need BIOS update |
| `intel_pstate=passive` kernel param passed | Check `cat /proc/cmdline` (none found) | Remove param |

### Resolution Path

1. **Check BIOS**: Reboot and look for "Intel Speed Shift Technology" or "Hardware P-State" settings
2. **Try LTS kernel**: In `configuration.nix`, change `boot.kernelPackages = pkgs.linuxPackages_6_6` (or whatever is current LTS)
3. **Force active mode**: Add `intel_pstate=active` to `boot.kernelParams`

### Can Run With
- `thermald` ✓ (thermald works with both active and passive mode)
- `power-profiles-daemon` ✓ (works better with active mode)
- `cachyos-tweaks.nix` ✓

---

## Issue 3: NVIDIA dGPU Always On

### Location
`system/gpu-nvidia.nix:26`

### What the Current Configuration Does

```nix
services.xserver.videoDrivers = ["nvidia"];  # Line 26 — loads nvidia driver at boot
hardware.nvidia.powerManagement.enable = true;      # Line 40 — enables PM
hardware.nvidia.powerManagement.finegrained = true;  # Line 41 — fine-grained PM
```

The NVIDIA driver loads at boot, initializing the GPU. `finegrained` power management enables runtime D3 (PCIe power state) support, but the GPU still draws power in P0 state.

### Power Consumption Impact

An idle RTX 3070 Laptop GPU typically draws:
- **P0 state** (current): ~10-15W (clocks at maximum)
- **P8 state** (deep idle): ~1-3W (clocks at minimum, memory in self-refresh)
- **D3cold** (PCIe D3, via no-gpu specialization): 0W

### How the GPU Stays in P0

The GPU's power management is controlled by:
1. **NVIDIA driver**: When loaded, initializes the GPU
2. **nvidia-persistenced**: Keeps the GPU initialized between process uses
3. **Runtime D3**: Allows PCIe transition to D3 hot when idle, but the GPU itself stays in P0

The `no-gpu` specialization (line 58-84) uses udev rules to physically remove the NVIDIA PCI device at boot:
```nix
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de",
  ATTR{class}=="0x03[0-9]*", ATTR{remove}="1"
```

This causes the kernel to remove the PCI device, fully powering it off (D3cold).

### Resolution Path

1. **Short-term**: Select `no-gpu` at boot menu when on battery
2. **Medium-term**: Create a systemd service that detects AC power state and applies/removes the udev rule dynamically
3. **Alternative**: Blacklist the nvidia modules entirely in default config and create a `with-gpu` specialization for when you need it

---

## Issue 4: All Power Config Commented Out

### Location
`modifications.nix:15,34-41` and `system/default.nix:6`

### What's Disabled

| Config Line | Status | Impact |
|---|---|---|
| `# ./cachyos-tweaks.nix` (line 15) | Not imported | Loses schedutil governor, ananicy, gamemode |
| `# powerManagement.cpuFreqGovernor = "performance"` (line 34) | Commented out | No explicit governor set |
| `# services.power-profiles-daemon.enable = false` (line 35) | Commented out | PPD is enabled by GNOME default (good) |
| `# services.upower.enable = true` (line 40) | Commented out | No battery monitoring daemon |
| `# services.thermald.enable = true` (line 41) | Commented out | No thermal management |

### Effect

The system operates with **only kernel defaults** plus what GNOME enables:
- `power-profiles-daemon` → enabled by GNOME, in `power-saver` mode
- No CPU governor explicitly set → kernel chooses `schedutil` (default for `intel_cpufreq`)
- No thermald → no proactive thermal management
- No upower → no battery status monitoring

---

## Issue 5: linuxPackages_latest Kernel

### Location
`configuration.nix:24`

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

Currently running Linux 7.0.11. With such a new kernel:
- Platform drivers for Tiger Lake may have regressions
- The `intel_pstate` driver behavior may have changed
- ACPI table parsing could differ from older kernels

### Resolution Path

Consider switching to `linuxPackages_6_6` (current LTS) or `linuxPackages_hardened` for stability.

---

## Configuration Compatibility Matrix

| Tool | Manages | thermald | PPD | TLP | auto-cpufreq | ananicy |
|---|---|---|---|---|---|---|
| **thermald** | Thermal throttling, power limits | — | ✓ | ~ | ~ | ✓ |
| **power-profiles-daemon** | Governor, EPP hints | ✓ | — | ✗ | ✗ | ✓ |
| **TLP** | Governor, USB autosuspend, disk, PCIe | ~ | ✗ | — | ~ | ✓ |
| **auto-cpufreq** | Governor, turbo, EPP | ~ | ✗ | ~ | — | ✓ |
| **ananicy** | IO priority, nice values | ✓ | ✓ | ✓ | ✓ | — |

Legend: ✓ = works together, ✗ = conflicts, ~ = overlaps (fine)

### Recommended Configuration for This System

```nix
# Primary thermal management
services.thermald.enable = true;

# Profile switching via GNOME/desktop
services.power-profiles-daemon.enable = true;  # Already enabled by GNOME

# Governor for passive mode fallback
powerManagement.cpuFreqGovernor = "powersave";

# OR import the full cachyos set
# (includes schedutil governor + ananicy + gamemode)
# (uncomment modifications.nix:15)
./cachyos-tweaks.nix
```

Do NOT run TLP alongside `power-profiles-daemon` — they conflict on governor management. Choose one or the other.

---

## Quick Fix (Minimal Changes)

To address overheating with minimal config changes:

1. **Uncomment `services.thermald.enable = true;`** in `modifications.nix:41` — this alone will provide proactive thermal management
2. **Set `powerManagement.cpuFreqGovernor = "powersave";`** explicitly
3. **Boot into `no-gpu` specialization** to remove NVIDIA heat load when on battery

These three changes require modifying only two lines in one file and a boot-menu selection.
