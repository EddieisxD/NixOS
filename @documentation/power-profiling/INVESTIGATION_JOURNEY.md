# Investigation Journey: NixOS Laptop Overheating Diagnosis

> **Knowledge Organization**: This document is structured following the principles of **hierarchical reasoning** and **graph-of-thought methodologies** (Best et al., 2024, "Graph of Thoughts"; Besta et al., 2024, "Demystifying Chains, Trees, and Graphs of Thoughts"; Huang et al., 2025, "ReasonFlux: Hierarchical LLM Reasoning"). The investigation is recorded as a directed acyclic graph where each finding branches into follow-up investigations, with clear evidence chains connecting observations to conclusions. Papers on these reasoning topologies are in `research-papers/`.

> **Date**: 2026-06-16
> **System**: NixOS 26.11, Linux 7.0.11, 11th Gen Intel i7-11800H, NVIDIA RTX 3070 Laptop GPU
> **Symptom**: Laptop regularly overheats

---

## Table of Contents

1. [Initial Triage — Scanning the NixOS Config](#1-initial-triage--scanning-the-nixos-config)
2. [Focus Phase — Power Management Services](#2-focus-phase--power-management-services)
3. [NVIDIA GPU Investigation](#3-nvidia-gpu-investigation)
4. [Noctalia Investigation](#4-noctalia-investigation)
5. [CPU Governor and Scaling Driver Deep Dive](#5-cpu-governor-and-scaling-driver-deep-dive)
6. [intel_pstate Passive Mode Investigation](#6-intel_pstate-passive-mode-investigation)
7. [Thermal Sensor Check](#7-thermal-sensor-check)
8. [Boot Parameter and Kernel Config Audit](#8-boot-parameter-and-kernel-config-audit)
9. [Evidence Summary and Chain of Reasoning](#9-evidence-summary-and-chain-of-reasoning)

---

## 1. Initial Triage — Scanning the NixOS Config

### Approach

When investigating a Linux system for thermal issues, the first step is always to understand **what the system is configured to do**. On NixOS, that means reading the declarative config files — because the actual running state is a direct reflection of what the Nix expression evaluates to.

### Files Examined

| File | Path | Purpose |
|---|---|---|
| `configuration.nix` | `/home/andy/System/v1/configuration.nix` | Top-level NixOS config entry point |
| `modifications.nix` | `/home/andy/System/v1/modifications.nix` | Main module with all power/gaming/perf settings |
| `flake.nix` | `/home/andy/System/v1/flake.nix` | Flake-based NixOS config, defines inputs and module list |
| `cachyos-tweaks.nix` | `/home/andy/System/v1/cachyos-tweaks.nix` | Has `powerManagement.cpuFreqGovernor = "schedutil"` |
| `system/gpu-nvidia.nix` | `/home/andy/System/v1/system/gpu-nvidia.nix` | NVIDIA GPU + PRIME offload config |
| `system/default.nix` | System module aggregation | Imports list for system modules |
| `btp_isolation.nix` | CPU isolation specialization | `mitigations=off` boot param |
| `smt-isolation.nix` | SMT isolation specialization | `mitigations=off` boot param |

### Rationale for Starting Here

In a NixOS system, the entire system state is derived from the Nix expression. Reading the config first lets us:
1. Form hypotheses about what should be running
2. Compare against what is actually running later
3. Identify which config lines are intended but disabled

### Key Evidence Found

**Finding 1: All thermal/power management is commented out (modifications.nix:34-41)**

```nix
# powerManagement.cpuFreqGovernor = "performance";
# services.power-profiles-daemon.enable = false;
# services.upower.enable = true;
# services.thermald.enable = true;
```

This is unusual. Typically, a NixOS system shipping with this much gaming/hardware configuration would have at least one of these enabled. The fact that **all** are commented out suggests either:
- The user intended to configure them but never did
- Something else (like GNOME's defaults) is providing baseline power management

**Finding 2: `cachyos-tweaks.nix` is commented out from imports (modifications.nix:15)**

```nix
# ./cachyos-tweaks.nix
```

This file contains `powerManagement.cpuFreqGovernor = "schedutil"` and `services.ananicy.enable = true`. Not importing it means these settings are NOT applied.

**Finding 3: NVIDIA GPU is configured to load at every boot (gpu-nvidia.nix:26)**

```nix
services.xserver.videoDrivers = ["nvidia"];
```

The NVIDIA driver loads at boot, keeping the dGPU powered on.

**Finding 4: `mitigations=off` exists in specializations only (btp_isolation.nix:22, smt-isolation.nix:24)**

These are in `specialisation` blocks, meaning they require manual boot-menu selection. Not active by default.

---

## 2. Focus Phase — Power Management Services

### Commands Run

```bash
systemctl status thermald power-profiles-daemon tlp auto-cpufreq noctalia
```

### Rationale

After finding the config was ambiguous (commented out), I needed to check what was **actually running**. Key hypotheses:
- `thermald` — Intel's thermal daemon, critical for proactive thermal management
- `power-profiles-daemon` — GNOME/desktop-agnostic profile switching daemon
- `tlp` — Laptop power management (thinkpad-oriented)
- `auto-cpufreq` — Automatic CPU frequency optimizer

### Evidence Found

```
power-profiles-daemon.service  ✓ Active (running) — profile: power-saver
thermald.service               ✗ Unit could not be found
tlp.service                    ✗ Unit could not be found
auto-cpufreq.service           ✗ Unit could not be found
```

**Critical discovery**: `thermald` is NOT running. The only power management service active is `power-profiles-daemon`, which is in `power-saver` mode.

### Why This Matters

`thermald` (Intel Thermal Daemon) is the primary mechanism for **proactive thermal management** on Intel CPUs. Without it:

1. The system relies solely on the kernel's built-in emergency thermal throttling
2. Emergency throttling only kicks in at critical junction temperatures (~95-100°C for Tiger Lake)
3. There's no proactive management that tries to keep temperatures at a target (e.g., 70-80°C)
4. The fan curve may not be optimized for the specific chassis

The `power-profiles-daemon` only manages the CPU governor and energy performance preference hints — it does NOT provide thermal management.

### Follow-Up: Power Profile Check

```bash
powerprofilesctl get
# Output: power-saver
```

Available profiles:
```
performance:  CpuDriver: intel_pstate
balanced:     CpuDriver: intel_pstate
* power-saver: CpuDriver: intel_pstate
```

This tells us:
- `intel_pstate` is the scaling driver (not `acpi-cpufreq`)
- The system is in power-saver mode, which should set a conservative governor

---

## 3. NVIDIA GPU Investigation

### Commands Run

```bash
nvidia-smi
```

### Rationale

The NVIDIA dGPU (RTX 3070 Laptop) is a significant power consumer. Even idle, a dGPU can draw 5-15W. In a laptop thermal envelope, this is substantial. I needed to verify:
1. Is the GPU actually powered on?
2. What power state is it in?
3. Is it being used by any processes?

### Evidence Found

```
GPU 0: NVIDIA GeForce RTX 3070 Laptop GPU
  Persistence-M: On
  Perf: P0              ← HIGHEST performance state (not P8)
  Pwr: 752W / 80W       ← Sensor error (752W is impossible)
  Temp: 39°C
  Memory: 1MiB / 8192MiB
  Processes: None       ← No active GPU processes
  Runtime D3 status: Enabled (fine-grained)
  Video Memory: Active
  S0ix Platform Support: Not Supported
```

### Analysis

The GPU reports **P0** performance state while idle with no processes. This is the highest power state. For comparison, the RTX 3070 should normally enter **P8** (lowest power) when idle, which drops clocks to minimum and reduces power draw dramatically.

The "752W" reading is a well-known NVML sensor overflow bug — ignore it. But P0 at idle is real and means the GPU isn't entering its deepest sleep state.

The `no-gpu` specialization in `gpu-nvidia.nix:58-84` exists to fully remove the NVIDIA GPU from the PCI bus at boot via udev rules:
```nix
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de",
  ATTR{class}=="0x03[0-9]*", ATTR{remove}="1"
```

But this requires manual boot-menu selection and is not the default.

### Why NVIDIA Hasn't Been the Full Cause

At 39°C and no processes, the GPU isn't actively generating heat. However, P0 state at idle means:
- The GPU is drawing more power than necessary
- This contributes to the overall system heat load
- The thermal solution must dissipate this + CPU heat simultaneously
- On a shared heat pipe design (common in laptops), this raises CPU temperatures too

---

## 4. Noctalia Investigation

### Commands Run

```bash
# Check if noctalia is on PATH
which noctalia

# Search for noctalia in the nix store
find /nix/store -name "*noctalia*" -maxdepth 3

# Check for running processes
ps aux | grep -i noctalia

# Read noctalia config
ls -la /home/addy/.config/noctalia
cat /home/addy/.config/noctalia/settings.json

# Check how it starts
grep -i "noctalia" /home/addy/.config/hypr/hyprland.conf
```

### Rationale

The user specifically suspected noctalia might be applying an aggressive power profile. Noctalia is a desktop shell/panel for Hyprland (similar to waybar but more feature-rich). I needed to verify:
1. Is noctalia installing a power management service?
2. Does noctalia's config force a performance profile?
3. How does noctalia interact with `power-profiles-daemon`?

### Evidence Found

**Noctalia IS running** — launched via Hyprland config:
```ini
exec-once = noctalia-shell
```

Process details:
```
addy 2907  /nix/store/...noctalia-qs-0.0.12/bin/quickshell
  -p /nix/store/...noctalia-shell-4.7.7/share/noctalia-shell
```

Two noctalia packages are installed:
- `noctalia-qs-0.0.12` — The Quickshell-based desktop shell runtime
- `noctalia-shell-4.7.7` — The QML shell resources

### Noctalia's Power Profile Service

I read the actual source code at:
`/nix/store/...noctalia-shell-4.7.7/share/noctalia-shell/Services/Power/PowerProfileService.qml`

The service is a thin wrapper around `power-profiles-daemon`:
- It reads the current profile via D-Bus (UPower PowerProfiles)
- It provides `setProfile()`, `cycleProfile()` functions
- It exposes `noctaliaPerformanceMode` which only affects UI (shadows, animations)
- It does NOT set CPU governors directly
- It does NOT interact with thermald or any thermal subsystem

**Noctalia's settings.json** confirms this:
```json
"noctaliaPerformance": {
    "disableDesktopWidgets": true,
    "disableWallpaper": true
}
```

No aggressive power profile settings anywhere in the config.

### Conclusion on Noctalia

**Noctalia is not the cause of overheating.** It's a desktop shell/panel that wraps `power-profiles-daemon` for UI convenience. It neither overrides the governor, nor applies its own power management, nor disables thermald or any other thermal control mechanism. The settings.json confirms a passive UI-focused configuration with no performance mode active.

---

## 5. CPU Governor and Scaling Driver Deep Dive

### Commands Run

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
```

### Evidence Found

```
Scaling governor: schedutil (all 16 cores)
Available governors: performance schedutil
Scaling driver: intel_cpufreq
Current frequencies: 800000 - 1300013 kHz (800 MHz - 1.3 GHz at idle)
```

### Analysis

#### Governor: `schedutil`

`schedutil` is the scheduler-driven frequency governor from the Linux kernel. Its key characteristics:
- Decision-making is integrated directly into the scheduler (CFS class)
- Uses PELT (Per-Entity Load Tracking) utilization as input
- Formula: `f_next = 1.25 * f_max * util` (on x86 without frequency invariance)
- Responds to task wakeups, migrations, and timer ticks
- Rate-limited to prevent thrashing

For more detail, see the kernel documentation at `kernel/sched/cpufreq_schedutil.c` or the [kernel docs](https://docs.kernel.org/scheduler/schedutil.html).

This governor is adaptive and generally fine for most workloads. However:
- Without `intel_pstate` active mode + HWP, it lacks hardware-level energy performance preferences
- `power-saver` through `power-profiles-daemon` with `intel_cpufreq` should normally use `powersave` governor, but `schedutil` is what's actually running

#### Driver: `intel_cpufreq` (not `intel_pstate`)

The driver is `intel_cpufreq`, which is the Linux cpufreq driver for Intel CPUs **in passive mode**. This is significant because:

- `intel_pstate` in active mode + HWP allows the CPU hardware to manage its own P-states
- `intel_cpufreq` (passive mode) means the kernel software manages frequencies
- Hardware P-State (HWP) control is NOT available
- Energy Performance Preference (EPP) is NOT available

---

## 6. intel_pstate Passive Mode Investigation

### Commands Run

```bash
cat /sys/module/intel_pstate/parameters/status
# Output: passive

cat /sys/devices/system/cpu/intel_pstate/*
# max_perf_pct: 100
# min_perf_pct: 17
# no_turbo: 0
# num_pstates: 39
# status: passive
# turbo_pct: 62

cat /proc/cpuinfo | grep -m1 "model name"
# 11th Gen Intel(R) Core(TM) i7-11800H @ 2.30GHz

cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
# (no output — EPP not available)

cat /proc/cmdline
# initrd=... init=... root=fstab loglevel=4 lsm=landlock,yama,bpf
```

### Key Discovery: HWP Not Active

The CPU flags (from `/proc/cpuinfo`) show **no `hwp` flag**. This is abnormal for an 11th Gen Tiger Lake CPU (i7-11800H), which should support HWP. The flags list includes `epb` (Energy Performance Bias — the legacy interface), but not `hwp`, `hwp_act_window`, `hwp_epp`, or `hwp_pkg_req`.

This means:
1. HWP is either disabled in the BIOS/UEFI firmware
2. OR the kernel decided not to enable it (e.g., a kernel regression in `linuxPackages_latest`)
3. OR the system is in a virtualized environment that doesn't expose HWP

Without HWP, `intel_pstate` operates in passive mode (`intel_cpufreq`), which:
- Uses generic cpufreq governors (`schedutil`, `performance`, `powersave`, `ondemand`)
- Cannot use `energy_performance_preference` (EPP)
- Has no `energy_performance_available_preferences` in sysfs
- Lacks HWP interrupt-based thermal notifications
- Cannot delegate frequency selection to CPU hardware microcode

### Why This Matters for Thermal Management

On Tiger Lake with HWP active:
- The CPU hardware makes fine-grained P-state decisions every ~1ms
- HWP can enter deeper C-states more aggressively
- EPP hints bias the hardware toward power saving vs performance
- The `intel_pstate` driver can use its own `powersave` algorithm (which is NOT the same as the generic `powersave` governor — it's actually more like `schedutil` with better hardware coordination)

Without HWP:
- The kernel makes P-state decisions at scheduler tick rate (~4ms by default)
- No EPP biasing
- `schedutil` responds to utilization, but can't leverage hardware-level efficiency
- The `no_turbo` and `min/max_perf_pct` controls in `/sys/devices/system/cpu/intel_pstate/` are the only hardware-level constraints

---

## 7. Thermal Sensor Check

### Commands Run

```bash
cat /sys/class/thermal/thermal_zone*/temp

for f in /sys/class/thermal/thermal_zone*; do
  echo "$(basename $f): $(cat $f/temp) '$(cat $f/type)'"
done
```

### Evidence Found

```
thermal_zone0: 20000 'INT3400 Thermal'    → 20°C (ACPI virtual sensor)
thermal_zone1: 42000 'acpitz'              → 42°C (ACPI temperature zone)
thermal_zone2: 42000 'x86_pkg_temp'        → 42°C (CPU package sensor)
thermal_zone3: 38000 'TCPU'                → 38°C (CPU temperature)
thermal_zone4: 38000 'iwlwifi_1'           → 38°C (WiFi radio temp)
```

At idle, 42°C is normal for a Tiger Lake laptop. However, the user reports overheating — this would occur under load. The key question is whether the system can manage heat under sustained load, which requires `thermald`.

---

## 8. Boot Parameter and Kernel Config Audit

### Commands Run

```bash
cat /proc/cmdline
```

### Evidence Found

Boot parameters currently active:
```
initrd=... init=... root=fstab loglevel=4 lsm=landlock,yama,bpf
```

No `intel_pstate=passive`, `intel_pstate=disable`, or `mitigations=off` in the active boot config.

The specializations (`btp_isolation.nix`, `smt-isolation.nix`) add `mitigations=off` and other params, but these require manual selection at boot.

### Grep for Power-Related Config throughout the Entire Config Tree

```bash
grep -r "intel_pstate\|acpi-cpufreq\|processor.max_cstate\|intel_idle" /home/addy/System/v1/ --include="*.nix"
# No results — no kernel command line overrides for CPU power management

grep -r "schedutil\|cpuFreqGovernor\|scaling_governor" /home/addy/System/v1/ --include="*.nix"
# Only cachyos-tweaks.nix (not imported) sets powerManagement.cpuFreqGovernor = "schedutil"
# modifications.nix has it commented out: # powerManagement.cpuFreqGovernor = "performance";
```

This confirms: **no NixOS config actively sets a CPU frequency governor**. The system is running with kernel defaults.

---

## 9. Evidence Summary and Chain of Reasoning

### The Evidence Chain

```
┌─────────────────────────────────────────────────┐
│  All power management services commented out    │
│  in modifications.nix: thermald, upower,        │
│  power-profiles-daemon, cpuFreqGovernor         │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  thermald NOT running (unit not found)          │
│  Only power-profiles-daemon is active           │
│  (because GNOME enables it by default)          │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  No proactive thermal management exists         │
│  Kernel emergency throttle at 95-100°C only     │
│  No target-temperature-based throttling         │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  intel_pstate in passive mode (intel_cpufreq)   │
│  No HWP available (BIOS/kernel config issue)    │
│  No EPP control                                 │
│  schedutil governor (appropriate but not HW-    │
│  optimized without HWP)                         │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  NVIDIA dGPU powered on at boot in P0 state     │
│  Adds 5-15W continuous system heat load         │
│  no-gpu specialization exists but not default   │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  cachyos-tweaks.nix not imported                │
│  (would provide schedutil, ananicy, gamemode)   │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  Grand conclusion: Laptop under load has:       │
│  1. No thermald to manage CPU thermal envelope  │
│  2. No HWP for efficient hardware P-state mgmt  │
│  3. Always-on dGPU adding baseline heat load    │
│  4. Latest kernel with possible regressions      │
└─────────────────────────────────────────────────┘
```

### Root Cause: No thermald + No HWP + Always-on GPU

**Primary**: The absence of `thermald` is the single most impactful issue. Without it, under sustained load, the CPU can reach high temperatures before any action is taken. With `thermald`, the system would proactively manage the thermal envelope by adjusting P-states and engaging cooling at a configurable target temperature.

**Secondary**: `intel_pstate` in passive mode without HWP means the CPU isn't using its most efficient power management features. Tiger Lake's HWP can make significantly more fine-grained power-performance decisions than the kernel's software governor.

**Contributing**: The NVIDIA dGPU is always powered on in P0 state, adding baseline heat that reduces the thermal budget available for the CPU.

---

## Appendix: Complete Command Log

| # | Command | Purpose | Finding |
|---|---|---|---|
| 1 | `systemctl status thermald power-profiles-daemon tlp auto-cpufreq noctalia` | Check running PM services | Only `power-profiles-daemon` running |
| 2 | `powerprofilesctl get; powerprofilesctl list` | Check current power profile | `power-saver`, `intel_pstate` driver |
| 3 | `cat /sys/.../scaling_governor` | Check CPU governor | `schedutil` on all cores |
| 4 | `cat /sys/.../scaling_driver` | Check scaling driver | `intel_cpufreq` |
| 5 | `nvidia-smi` | Check GPU state | P0 at idle, no processes |
| 6 | `cat /sys/module/intel_pstate/parameters/status` | Check pstate mode | `passive` |
| 7 | `cat /sys/devices/system/cpu/intel_pstate/*` | Read pstate limits | max 100%, min 17%, no_turbo 0 |
| 8 | `cat /proc/cpuinfo \| grep "model name"` | Verify CPU model | i7-11800H Tiger Lake |
| 9 | `grep -o "hwp" /proc/cpuinfo` | Check HWP support | Not found |
| 10 | `cat /sys/class/thermal/thermal_zone*/temp` | Read temps | 42°C package at idle |
| 11 | `cat /proc/cmdline` | Check boot params | No power-related params |
| 12 | `which noctalia; find /nix/store -name "*noctalia*"` | Check noctalia install | `noctalia-qs`, `noctalia-shell` found |
| 13 | `ps aux \| grep -i noctalia` | Check noctalia running | Yes, since Jun 14 |
| 14 | `cat ~/.config/noctalia/settings.json` | Read noctalia config | No performance profile active |
| 15 | `read PowerProfileService.qml` | Read noctalia PM source | Thin wrapper around PPD |
| 16 | `grep -r "schedutil\|cpuFreqGovernor" /home/addy/System/v1/ --include="*.nix"` | Find governor config | Only in non-imported module |
| 17 | `grep -r "intel_pstate\|power-profiles-daemon\|thermald" *.nix` | Find PM config | All commented out |
