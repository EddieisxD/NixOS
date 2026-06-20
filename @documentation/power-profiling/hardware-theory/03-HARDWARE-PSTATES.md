# Hardware P-States (HWP): The CPU's Internal Governor

## Table of Contents

1. [What Is HWP?](#1-what-is-hwp)
2. [HWP Capabilities and MSR Interface](#2-hwp-capabilities-and-msr-interface)
3. [Energy Performance Preference (EPP)](#3-energy-performance-preference-epp)
4. [HWP Interrupts and Thermal Notifications](#4-hwp-interrupts-and-thermal-notifications)
5. [Intel Speed Shift](#5-intel-speed-shift)
6. [AMD CPPC Comparison](#6-amd-cppc-comparison)
7. [Why HWP Matters for Thermal Management](#7-why-hwp-matters-for-thermal-management)
8. [Diagnosing HWP on Your System](#8-diagnosing-hwp-on-your-system)

---

## 1. What Is HWP?

Hardware P-States (HWP) is an Intel technology that allows the CPU hardware to manage its own P-states. Introduced in Haswell (4th gen, 2013) and significantly improved in Skylake (6th gen, 2015), HWP represents a shift from OS-controlled to hardware-controlled frequency management.

### Key Insight

Before HWP, the OS had to make frequency decisions with stale data:
- The OS knows workload history (PELT, utilization over ~32ms decay)
- The CPU hardware knows instantaneous conditions (current instruction mix, cache misses, pipeline stalls, temperature, power budget)

With HWP, the CPU's PCU (Power Control Unit) makes decisions with µs-level granularity based on real-time hardware telemetry.

### What HWP Changes

| Aspect | Without HWP | With HWP |
|---|---|---|
| Decision maker | OS (schedutil/ondemand) | CPU PCU hardware |
| Update granularity | ~4-10ms (scheduler tick rate-limited) | ~1ms (hardware loop) |
| Input data | PELT utilization (running time) | ~200+ hardware signals |
| Output | MSR write (MSR_PERF_CTL) | Internal voltage/freq change |
| OS role | Select specific frequency | Provide hints (min, max, EPP) |
| Thermal response | Polling-based (~1-5s with thermald) | Interrupt-driven (milliseconds) |

---

## 2. HWP Capabilities and MSR Interface

### HWP Detection

HWP availability is indicated by CPUID flags:

```bash
grep "hwp" /proc/cpuinfo | head -1
# Should show: hwp hwp_act_window hwp_epp hwp_pkg_req
```

Our i7-11800H system does NOT show these flags, confirming HWP is not active.

### MSR_HWP_CAPABILITIES (0x771)

Read-only register that reports the CPU's HWP capabilities:

```
Bits 7:0     Highest performance (the maximum possible P-state)
Bits 15:8    Guaranteed performance (base frequency P-state)
Bits 23:16   Most efficient performance (lowest power at base freq)
Bits 31:24   Lowest performance (minimum voltage P-state)
Bits 39:32   Lowest non-linear performance (optimum efficiency point)
```

### MSR_HWP_REQUEST (0x774)

The OS writes this register to set HWP parameters:

```
Bits 7:0     Minimum performance (0-255)
Bits 15:8    Maximum performance (0-255)
Bits 23:16   Desired performance (0-255, optional hint)
Bits 31:24   Energy Performance Preference (EPP, 0-255)
Bits 41:32   Activity Window (time constant for workload averaging)
Bits 60      Package control (apply to all cores in package)
Bits 63      Fault handling
```

### MSR_HWP_STATUS (0x777)

Reports HWP status including thermal conditions:

```
Bit 0:       Guaranteed performance change (when thermal limits change)
Bit 1:       Excursion to minimum (CPU requests min due to thermal)
```

### How the OS Uses HWP

```nix
# In kernel intel_pstate.c, active mode + HWP:

# 1. Driver reads CPUID to discover HWP support
# 2. Driver reads MSR_HWP_CAPABILITIES to get min/max/efficient
# 3. When governor requests a change:
#    - "performance" governor: EPP = 0, max_perf = 255
#    - "powersave" governor: EPP = 128, max_perf = 255
# 4. Driver writes MSR_HWP_REQUEST, or
#    writes MSR_HWP_REQUEST_PKG (0x772) for package-wide

# If EPP change only (common path):
wrmsr MSR_HWP_REQUEST, (current_value & ~0xFF000000) | (epp << 24)
```

---

## 3. Energy Performance Preference (EPP)

EPP is an 8-bit value (0-255) that tells the CPU hardware how to bias its performance/power decisions. Lower values favor performance, higher values favor power saving.

### Named EPP Values

| Named Value | Numeric (typical) | Behavioral Effect |
|---|---|---|
| `performance` | 0 | Maximum performance bias. CPU enters turbo aggressively and stays high. |
| `balance_performance` | 64 | Balanced but performance-leaning. Faster ramp-up, slower ramp-down. |
| `default` | 128 | Neutral. Hardware decides based on workload. |
| `balance_power` | 192 | Balanced but power-leaning. Faster ramp-down, slower ramp-up. |
| `power` | 255 | Maximum power saving. CPU minimizes frequency aggressively. |

### How EPP Affects Behavior

```
EPP = 0 (performance):
  CPU spends more time at high frequencies
  Quick to enter turbo, slow to leave it
  Higher power, lower latency

EPP = 128 (default):
  CPU adjusts based on real workload
  Uses PELT-like tracking internally
  Balanced power/performance

EPP = 255 (power):
  CPU minimizes frequencies aggressively
  Slow to ramp up, quick to ramp down
  Lower power, higher latency
```

### Checking EPP on Your System

```bash
# With HWP active:
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
# With HWP available:
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_available_preferences

# Set EPP:
echo power | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
echo 255 | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference  # Same
```

### Legacy EPB (Energy Performance Bias)

Before HWP, Intel CPUs had EPB — a simpler hint mechanism using MSR_IA32_ENERGY_PERF_BIAS (0x1B0):

```
Bits 3:0     Energy Performance Bias (0-15)
  0 = Performance
  4 = Balance performance (default on most systems)
  7 = Balance power
  15 = Power save
```

EPB is still present on HWP-capable CPUs but is less nuanced than EPP.

---

## 4. HWP Interrupts and Thermal Notifications

One of HWP's key advantages for thermal management is its ability to generate interrupts when thermal conditions change.

### MSR_HWP_INTERRUPT (0x773)

The OS can enable interrupts for:
- Change in guaranteed performance (due to thermal/power constraints)
- Excursion to minimum performance (CPU is too hot)

### Thermal Flow with HWP

```
1. CPU gets hot
2. PCU detects via DTS (not OS polling — hardware level)
3. PCU autonomously reduces P-states (within ms, no OS involvement)
4. If efficiency cap changes:
   a. PCU updates MSR_HWP_CAPABILITIES guaranteed performance field
   b. Generates interrupt to OS
5. OS notices via interrupt handler
   a. Updates thermal subsystem
   b. thermald gets notified via sysfs/netlink
6. thermald can increase cooling if needed
```

**Key benefit**: The hardware protects itself BEFORE the OS even knows there's a problem. With passive mode (no HWP), the OS must discover the temperature through polling, which has a 1-5 second latency.

---

## 5. Intel Speed Shift

Intel Speed Shift is the marketing name for HWP. It was introduced in two phases:

- **Speed Shift 1.0**: Skylake (6th gen, 2015) — Basic HWP support
- **Speed Shift 2.0**: Kaby Lake R / Coffee Lake (8th gen, 2017) — Improved responsiveness

Speed Shift 2.0 adds:
- Faster P-state ramp-up (from several ms to ~1ms)
- Better workload prediction
- Improved energy efficiency

Tiger Lake (our CPU) supports Speed Shift 2.0 with additional enhancements.

---

## 6. AMD CPPC Comparison

AMD's equivalent of HWP is CPPC (Collaborative Processor Performance Control), part of the ACPI specification:

| Feature | Intel HWP | AMD CPPC |
|---|---|---|
| First available | Haswell (2013) | Zen 2 (2019) |
| OS hint mechanism | EPP (MSR 0x774) | Autonomous (CPPC) + EPP |
| Linux driver | `intel_pstate` | `amd_pstate` + `amd_pstate_epp` |
| Capabilities MSR | MSR_HWP_CAPABILITIES (0x771) | CPPC capabilities via ACPI |
| Highest perf register | MSR_HWP_REQUEST (0x774) | CPC in ACPI |
| Kernel mode | `active` / `passive` | `active` / `guided` / `passive` |

### amd_pstate Modes

| Mode | Behavior | Kernel requirement |
|---|---|---|
| `active` | Autonomous mode (like HWP + EPP) | 6.3+ |
| `guided` | Semi-autonomous (hardware decides within OS-specified constraints) | 6.4+ |
| `passive` | OS-controlled (like intel_cpufreq) | All |

---

## 7. Why HWP Matters for Thermal Management

### The Thermal Lag Problem

Without HWP, the thermal feedback loop is:

```
CPU heats up → ... → ... → schedutil sees high util → raises freq → MORE heat
                                               ↓
                            (schedutil doesn't know it's hot)
                                               ↓
                            thermald polls temp → 1-5s later → engages cooling
```

With HWP:

```
CPU heats up → PCU detects → HWP reduces freq ← IN MILLISECONDS
             → (possibly interrupts OS if limit reached)
```

### Practical Impact

On Tiger Lake (or any modern Intel CPU), HWP with `power` EPP hint would:
- Keep frequencies lower under sustained load (better thermals)
- Transition to low power states faster during brief idle periods
- Respond to thermal conditions before they become critical

Without HWP (our current state), `schedutil` with `power-saver` profile provides marginal power saving, but lacks the hardware-level thermal responsiveness.

---

## 8. Diagnosing HWP on Your System

### Check if HWP Is Available

```bash
# Method 1: CPU flags
cat /proc/cpuinfo | grep -m1 "flags" | grep -o "hwp"

# Method 2: MSR access
sudo modprobe msr
sudo rdmsr -a 0x771  # Read HWP_CAPABILITIES
# If returns 0 (all CPUs) or raises SIGBUS, HWP is NOT available

# Method 3: intel_pstate sysfs
cat /sys/devices/system/cpu/intel_pstate/status
# "active" → HWP available
# "passive" → HWP not available or disabled
```

### Why HWP Might Be Unavailable

1. **BIOS disabled**: Check for "CPU Power Management" / "Intel Speed Shift" settings
2. **Kernel too old**: Pre-5.7 kernels handle HWP differently
3. **Kernel regression**: Newer kernels (`linuxPackages_latest`) may have issues on Tiger Lake
4. **Virtualization**: HWP is typically not exposed to VMs
5. **msr kernel module not loaded**: `sudo modprobe msr` enables /dev/cpu/*/msr

### References

- Intel SDM, Vol. 3B: Chapter 14.3 — Hardware-Controlled P-States (HWP)
- Intel SDM, Vol. 4: Model-Specific Registers (MSR_HWP_REQUEST, etc.)
- Linux kernel source: `drivers/cpufreq/intel_pstate.c` — `__intel_pstate_get_cpufreq_med` functions
- Kernel documentation: [Intel P-State Driver](https://docs.kernel.org/admin-guide/pm/intel_pstate.html)
- Phoronix: [Intel Speed Shift / HWP Benchmarks](https://www.phoronix.com/scan.php?page=article&item=linux-hwp-intel&num=1)
