# The intel_pstate Driver: Active vs Passive Mode

## Table of Contents

1. [Overview](#1-overview)
2. [Active Mode (With HWP)](#2-active-mode-with-hwp)
3. [Active Mode (Without HWP)](#3-active-mode-without-hwp)
4. [Passive Mode (intel_cpufreq)](#4-passive-mode-intel_cpufreq)
5. [Comparison: Active vs Passive](#5-comparison-active-vs-passive)
6. [Kernel Boot Parameters](#6-kernel-boot-parameters)
7. [The Tiger Lake Case: Why It Matters](#7-the-tiger-lake-case-why-it-matters)

---

## 1. Overview

`intel_pstate` is a CPU performance scaling driver for Intel processors (Sandy Bridge and newer). It is a single driver that serves two roles:

1. **A scaling driver** — interfaces with the hardware
2. **A scaling governor** — has its own internal algorithms

Unlike `acpi-cpufreq` which only translates OS-frequency-requests to hardware P-states, `intel_pstate` understands the Intel P-state model and can operate in multiple modes.

### Operation Modes Summary

| Mode | scaling_driver | Governors Available | HWP Used? | Kernel Parameter |
|---|---|---|---|---|
| **Active + HWP** | `intel_pstate` | `powersave`, `performance` | Yes | Default (HWP-capable CPUs) |
| **Active, no HWP** | `intel_pstate` | `powersave`, `performance` | No | `intel_pstate=active` |
| **Passive** | `intel_cpufreq` | All generic | No | `intel_pstate=passive` (or HWP unavailable) |

### Detection

```bash
# Check current mode
cat /sys/devices/system/cpu/intel_pstate/status
# "active" or "passive" or "off"

# Check scaling driver
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
# "intel_pstate" or "intel_cpufreq"
```

From the kernel documentation:
> If `intel_pstate` works in the active mode, the `scaling_driver` attribute in sysfs for all CPUFreq policies contains the string "intel_pstate". In the passive mode, it contains "intel_cpufreq".

---

## 2. Active Mode (With HWP)

This is the ideal configuration for modern Intel CPUs that support HWP (Broadwell and newer, effectively).

### How It Works

1. The driver enables HWP during CPU initialization
2. The driver provides the processor with:
   - **Performance limits**: Min and max performance levels via MSR_HWP_REQUEST
   - **Energy Performance Preference (EPP)**: A hint biasing toward power saving or performance
   - **Activity window**: How far ahead the hardware should look (hwp_act_window)
3. The CPU's internal PCU (Power Control Unit) selects P-states autonomously
4. The driver registers utilization callbacks — not for P-state selection, but only to update `scaling_cur_freq` for sysfs

### The Two "Governors" in Active Mode

In active mode, `intel_pstate` provides its own "governors" that share names with generic governors but work completely differently:

#### `powersave` (Intel-specific, active mode)

This is NOT the generic powersave governor. In active mode with HWP:
- The driver writes `EPP = 128` (balance_performance? default) or `EPP = 128+` (power-save bias)
- The hardware selects frequencies based on workload
- Generally provides dynamic scaling similar to schedutil but with better hardware coordination

From the kernel docs:
> The `powersave` algorithm is not a counterpart of the generic `powersave` governor. Roughly, it corresponds to the `schedutil` and `ondemand` governors.

#### `performance` (Intel-specific, active mode)

- The driver writes `EPP = 0` (performance bias)
- The hardware maintains higher frequencies more aggressively
- Still allows frequency reduction when completely idle
- NOT the same as the generic `performance` governor (which pegs frequency at max)

### key sysfs Controls (active mode + HWP)

```bash
# Energy Performance Preference
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
# Available preferences
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_available_preferences
# "default performance balance_performance balance_power power"
# Or a number 0-255 (0 = max performance, 255 = max power saving)
```

### How EPP Translates to MSRs

EPP is stored in the MSR_HWP_REQUEST register (0x774), bits 31:24:

```
MSR_HWP_REQUEST [63:0]
  [7:0]   Minimum performance
  [15:8]  Maximum performance
  [23:16] Desired performance
  [31:24] Energy Performance Preference (EPP)
  [41:32] Activity window
  [60]    Package control
```

On Tiger Lake, the default EPP values for each hint are:
- `performance`: EPP = 0 (or 32 in some implementations)
- `balance_performance`: EPP = 64
- `default`: EPP = 128
- `balance_power`: EPP = 192
- `power`: EPP = 255

---

## 3. Active Mode (Without HWP)

If the CPU supports `intel_pstate` but does NOT support HWP, the driver can still operate in active mode by kernel parameter `intel_pstate=active`.

### How It Differs

- The driver's internal algorithm selects P-states directly (no hardware delegation)
- Still bypasses the generic governor layer
- Only `powersave` and `performance` are listed as governors
- No EPP controls (energy_performance_preference not available)
- No HWP-related MSRs used

This mode provides no real benefit over passive mode on such CPUs.

---

## 4. Passive Mode (intel_cpufreq)

This is what our system is running. In this mode, `intel_pstate` registers itself as a standard cpufreq driver (`intel_cpufreq`).

### How It Works

1. The driver registers with the cpufreq core as a standard scaling driver
2. Generic governors (schedutil, ondemand, performance, powersave, etc.) select target frequencies
3. The driver translates these frequency requests to P-states via MSR writes
4. Uses MSR_PERF_CTL (0x199) to request specific P-states
5. No HWP interaction, no EPP hints

### When It's Used

The kernel selects passive mode when:
1. The CPU does not support HWP (pre-Broadwell, ~2014)
2. The CPU supports HWP but the BIOS/firmware doesn't enable it
3. The kernel param `intel_pstate=passive` is given
4. Hybrid CPU configurations that don't support active mode

From kernel docs:
> Starting with kernel 5.7, the intel_pstate driver selects passive mode aka intel_cpufreq for CPUs that do not support hardware-managed P-states (HWP), i.e., Intel Core i 5th gen. or older.

**However**, Tiger Lake (11th gen) should support HWP. The fact that it's in passive mode is abnormal and suggests a firmware or BIOS issue.

### What's Lost in Passive Mode

| Feature | Active + HWP | Passive |
|---|---|---|
| Hardware P-State selection | ✓ CPU decides | ✗ OS decides |
| Energy Performance Preference | ✓ EPP hints | ✗ Not available |
| Per-core autonomous control | ✓ | OS-controlled |
| HWP thermal interrupts | ✓ | ✗ |
| Fast P-state transitions (~1ms) | ✓ | ~10-20ms (rate-limited) |
| Package-level power optimization | ✓ | ✗ |

---

## 5. Comparison: Active vs Passive

### Performance Characteristics

| Aspect | Active + HWP | Passive (intel_cpufreq) |
|---|---|---|
| Single-thread turbo responsiveness | Excellent (hardware responds in μs) | Good (schedutil responds in ms) |
| Multi-thread power efficiency | Better (package-level optimization) | Good (per-policy optimization) |
| Idle power | Lower (faster C-state entry) | Slightly higher |
| Thermal responsiveness | Better (HWP interrupts) | Delayed (scheduler tick) |
| Determinism | Less (hardware makes decisions) | More (OS controls everything) |

### When Each Is Preferred

- **Active + HWP**: General use, laptops, most desktops — best power/performance balance
- **Passive**: When deterministic control is needed (real-time, benchmarking), or when HWP is unavailable

---

## 6. Kernel Boot Parameters

| Parameter | Effect |
|---|---|
| `intel_pstate=disable` | Completely disables intel_pstate, falls back to acpi-cpufreq |
| `intel_pstate=passive` | Forces passive mode (intel_cpufreq) |
| `intel_pstate=active` | Forces active mode (no HWP delegation on non-HWP CPUs) |
| `intel_pstate=no_hwp` | Disables HWP even if available (effectively active mode without HWP) |
| `intel_pstate=per_cpu_perf_limits` | Per-CPU performance limits |
| `processor.max_cstate=1` | Limit max C-state (for stability testing) |
| `intel_idle.max_cstate=4` | Limit intel_idle C-states |

---

## 7. The Tiger Lake Case: Why It Matters

The system has an i7-11800H (Tiger Lake-H) with `intel_pstate` running in passive mode. This means:

1. **HWP is not being used** despite Tiger Lake supporting it
2. **No EPP control** — can't bias the CPU toward power saving
3. **Software-managed P-states** via schedutil, which is less thermally efficient

### Why This Causes Overheating

Without HWP, the thermal management chain is:

```
Load → Scheduler → PELT → schedutil → freq request → intel_cpufreq → MSR write → CPU
```

With HWP, it would be:
```
Load → CPU PCU detects → hardware P-state transition (~1μs latency)
  PLUS: EPP hint from OS biases the decision toward power saving
```

The hardware can respond faster to thermal conditions and make better package-level decisions. Under load, an HWP-capable CPU with `power` EPP hint will:
- Be more aggressive about entering lower P-states during brief idle periods
- Better balance temperature across cores
- Reduce frequency faster when thermal headroom is needed

### Resolution

1. **Check BIOS**: Look for "Intel Speed Shift Technology" or "HWP" setting
2. **Try `intel_pstate=active`** kernel parameter
3. **Check kernel dmesg**: `dmesg | grep intel_pstate` for clues about why HWP isn't being enabled

### References

- Linux kernel source: `drivers/cpufreq/intel_pstate.c`
- Kernel documentation: [intel_pstate.rst](https://docs.kernel.org/admin-guide/pm/intel_pstate.html)
- Intel SDM, Vol. 3B: Chapter 14.3 — Hardware-Controlled P-States (HWP)
- Intel SDM, Vol. 4: MSR reference (MSR_HWP_REQUEST, MSR_HWP_CAPABILITIES, etc.)
