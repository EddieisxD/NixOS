# MSRs and CPU Registers: The Hardware Control Interface

## Table of Contents

1. [What Are MSRs?](#1-what-are-msrs)
2. [Power Management MSRs on Intel CPUs](#2-power-management-msrs-on-intel-cpus)
3. [Thermal Monitoring MSRs](#3-thermal-monitoring-msrs)
4. [RAPL MSRs](#4-rapl-msrs)
5. [HWP MSRs](#5-hwp-msrs)
6. [Reading and Writing MSRs on Linux](#6-reading-and-writing-msrs-on-linux)
7. [Safety Considerations](#7-safety-considerations)

---

## 1. What Are MSRs?

Model-Specific Registers (MSRs) are control registers in x86 CPUs that provide:
- Interface to CPU features (power management, thermal monitoring, performance counters)
- Configuration and status reporting
- Debug and diagnostic capabilities

Each MSR is identified by a 32-bit address (e.g., 0x199). MSRs are accessed via the `rdmsr` and `wrmsr` instructions, available only to ring 0 (kernel).

### MSR Categories

| Category | Address Range | Examples |
|---|---|---|
| Architectural MSRs | 0x00 - 0xFF | MSR_APIC_BASE (0x1B), MSR_EFER (0xC0000080) |
| Power management | 0x198 - 0x1B2 | PERF_CTL, PERF_STATUS, THERM_STATUS |
| RAPL | 0x606 - 0x641 | PKG_POWER_LIMIT, DRAM_POWER_LIMIT |
| HWP | 0x771 - 0x777 | HWP_REQUEST, HWP_CAPABILITIES |
| Specific to CPU model | Various | Determined by CPUID |

---

## 2. Power Management MSRs on Intel CPUs

### MSR_PERF_CTL (0x199) — P-State Request

Used by the OS (or firmware) to request a specific P-state target. This is the legacy interface; on HWP systems, MSR_HWP_REQUEST is used instead.

```
Bits 15:0    Target P-state ID (OS-requested P-state)
Bits 31:16   Reserved
Bits 32:32   IO transition enable
Bits 63:33   Reserved
```

Reading on our system:
```bash
sudo rdmsr -a -d 0x199
# 0 (typically means lowest P-state at idle)
```

### MSR_PERF_STATUS (0x198) — Current P-State

Read-only register reflecting the current P-state.

```
Bits 15:0    Current P-state ID
Bits 31:16   Reserved
Bits 47:32   Current frequency (in 100MHz units on some implementations)
Bits 63:48   Reserved
```

### MSR_IA32_ENERGY_PERF_BIAS (0x1B0) — Legacy EPB

Provides a simple performance/power preference hint (pre-HWP).

```
Bits 3:0     Energy Performance Bias (0-15)
  0   = Performance
  4   = Balance Performance (default on most desktop/laptop systems)
  7   = Balance Power (common default for battery)
  15  = Power Save
Bits 63:4    Reserved
```

### MSR_IA32_MPERF (0xE7) and MSR_IA32_APERF (0xE8)

These counters track actual vs maximum frequency:

- **MPERF**: Counts at constant rate (TSC frequency, ~2.3 GHz base)
- **APERF**: Counts at actual CPU frequency (varies with P-state)

The ratio `APERF/MPERF` gives the average frequency multiplier. Used by:
- `turbostat` to calculate actual power
- schedutil (on x86) for frequency scale invariance compensation

```bash
sudo rdmsr -a -d 0xE7   # MPERF
sudo rdmsr -a -d 0xE8   # APERF
```

---

## 3. Thermal Monitoring MSRs

### MSR_IA32_THERM_STATUS (0x19C)

Core thermal status register. Provides real-time temperature data.

```
Bits 7:0     Digital thermal sensor reading
             (relative to TjunctionMax, in degrees Celsius)
             Higher value = closer to TjunctionMax
Bits 15:8     Reserved
Bit 16       Thermal throttle status (1 = throttling active)
Bit 17       Thermal throttle log
Bit 18       PROCHOT status (1 = processor hot asserted)
Bit 19       PROCHOT log
Bit 20       Critical temperature status
Bit 21       Critical temperature log
Bit 22       Thermal interrupt pending
Bits 31:23   Reserved
```

### MSR_IA32_PACKAGE_THERM_STATUS (0x1B2)

Same as IA32_THERM_STATUS but for the entire CPU package.

### MSR_IA32_TEMPERATURE_TARGET (0x1A2)

Reports the minimum and maximum temperatures:

```
Bits 15:0    TjunctionMax (maximum junction temperature, in °C)
Bits 23:16   TjunctionMin (minimum for effective cooling, in °C)
Bits 31:24   Reserved
```

On i7-11800H, TjunctionMax is typically 100°C.

```bash
sudo rdmsr -d 0x1A2
# Parse: TjunctionMax = (value & 0xFFFF) = ~100°C typical for Tiger Lake
```

### MSR_IA32_PACKAGE_THERM_INTERRUPT (0x1B3)

Configures thermal interrupt thresholds. Used by the kernel to enable:
- PROCHOT interrupt on temperature threshold
- Thermal throttle count threshold interrupt

---

## 4. RAPL MSRs

### MSR_RAPL_POWER_UNIT (0x606)

Defines the units for all RAPL register values:

```
Bits 3:0     Power units, in Watts (typically 0.125W = 1/8 W per LSB)
Bits 7:4     Reserved
Bits 12:8    Energy units, in Joules (typically 1/65536 J = 15.3 μJ per LSB)
Bits 15:13   Reserved
Bits 19:16   Time units, in seconds (typically 1/976.56 μs per LSB)
Bits 63:20   Reserved
```

### MSR_PKG_POWER_LIMIT (0x610)

Controls the package power limits (PL1, PL2).

```
Bit 0-14:    PL1 power limit (in POWER_UNIT, typically 1/8 W steps)
Bit 15:      PL1 enable
Bit 16:      PL1 clamp enable
Bit 17-20:   PL1 time window (Tau)
Bits 21-22:  PL1 tau extension
Bit 23:      Reserved
Bit 24-38:   PL2 power limit (in POWER_UNIT)
Bit 39:      PL2 enable
Bit 40:      PL2 clamp enable
Bit 41-44:   PL2 time window
Bits 45-46:  PL2 tau extension
Bit 47:      Lock (if 1, MSR cannot be modified until reset)
Bits 63-48:  Reserved
```

Example: Setting PL1 to 45W
```bash
# 45W = 45 / 0.125 = 360 units
sudo wrmsr 0x610 $((360 | (1 << 15)))
# 360 | (1 << 15) = 0x168
```

### MSR_PKG_ENERGY_STATUS (0x611)

Monotonically increasing energy counter for the entire package:

```bash
sudo rdmsr -d 0x611
# Value in ENERGY_UNIT (typically 15.3 μJ per count)
# Read twice with interval to calculate power:
# Power = (count2 - count1) * 15.3μJ / interval_seconds
```

### Other RAPL MSRs

| MSR | Address | Domain |
|---|---|---|
| MSR_PP0_POWER_LIMIT | 0x638 | Core domain (PP0) |
| MSR_PP0_ENERGY_STATUS | 0x639 | Core energy counter |
| MSR_PP1_POWER_LIMIT | 0x641 | Graphics domain (PP1) |
| MSR_PP1_ENERGY_STATUS | 0x642 | Graphics energy counter |
| MSR_DRAM_POWER_LIMIT | 0x618 | DRAM domain |
| MSR_DRAM_ENERGY_STATUS | 0x619 | DRAM energy counter |
| MSR_PLATFORM_POWER_LIMIT | 0x6C0 | Platform (PSys) domain |

---

## 5. HWP MSRs

See [Chapter 3: Hardware P-States](./03-HARDWARE-PSTATES.md) for full details. Summary:

| MSR | Address | Size | Description |
|---|---|---|---|
| MSR_HWP_CAPABILITIES | 0x771 | 64-bit | Capabilities (highest, guaranteed, most efficient, lowest) |
| MSR_HWP_REQUEST_PKG | 0x772 | 64-bit | Package-level HWP request |
| MSR_HWP_INTERRUPT | 0x773 | 64-bit | HWP interrupt enable |
| MSR_HWP_REQUEST | 0x774 | 64-bit | Per-core HWP request (min, max, EPP) |
| MSR_HWP_STATUS | 0x777 | 64-bit | HWP status (guaranteed change, excursion) |

---

## 6. Reading and Writing MSRs on Linux

### Tools

```bash
# rdmsr/wrmsr (part of msr-tools package)
rdmsr 0x199           # Read MSR 0x199 on CPU 0
rdmsr -a 0x199        # Read on all CPUs
rdmsr -d 0x199        # Decimal output
rdmsr -x 0x199        # Hex output
rdmsr -f 15:0 0x199   # Extract bits 15:0 (bitfield mask)
wrmsr 0x199 0x0A00    # Write 0x0A00 to MSR 0x199 on CPU 0
wrmsr -a 0x199 0x0A00 # Write on all CPUs
```

### Kernel Module

The `msr` kernel module creates `/dev/cpu/*/msr` character devices:

```bash
sudo modprobe msr
ls /dev/cpu/*/msr
/dev/cpu/0/msr  /dev/cpu/1/msr  ...  /dev/cpu/15/msr
```

### Direct Read from Userspace

```c
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd = open("/dev/cpu/0/msr", O_RDONLY);
    unsigned long long val;
    pread(fd, &val, 8, 0x19C);  // Read MSR 0x19C (THERM_STATUS)
    printf("MSR 0x19C = 0x%llx\n", val);
    close(fd);
    return 0;
}
```

### Tools That Use MSRs

| Tool | MSRs Used | Purpose |
|---|---|---|
| `turbostat` | MPERF (0xE7), APERF (0xE8), RAPL, THERM_STATUS | Power/thermal monitoring |
| `x86_energy_perf_policy` | ENERGY_PERF_BIAS (0x1B0), HWP_REQUEST (0x774) | Set power/performance policy |
| `thermald` | RAPL MSRs | Set power limits |
| `cpupower` | PERF_CTL (0x199) | Set governor/frequency |
| `intel_gpu_top` | GPU registers | GPU utilization/power |

---

## 7. Safety Considerations

### RISK WARNING

Writing to MSRs can:
- **Crash the system** (wrong value in a control register)
- **Overheat the CPU** (disabling thermal protection)
- **Damage hardware** (overvoltage, excessive power draw)
- **Corrupt data** (memory controller MSR errors)

### Safe Practices

1. **Never write to an MSR you don't fully understand**
2. **Always read the Intel SDM** for the specific MSR's bit layout
3. **Prefer sysfs interfaces** — the kernel validates values:
   ```bash
   # SAFE: kernel validates the value
   echo 60 > /sys/devices/system/cpu/intel_pstate/max_perf_pct

   # DANGEROUS: bypasses kernel validation
   wrmsr 0x610 0x...  # Can set invalid power limits
   ```
4. **Back up original values** before writing:
   ```bash
   sudo rdmsr -a 0x610 > rapl_backup.txt
   ```
5. **Use `msr-safe`** (LLNL project) for safer MSR access in production

### References

- Intel Software Developer's Manual, Volume 4: Model-Specific Registers
  - Complete MSR listing for all Intel CPU families
  - Bit-level descriptions for every MSR
- Intel SDM, Volume 3B: Chapters 14 (Power), 15 (Thermal)
- `msr-tools` package: man pages for `rdmsr`, `wrmsr`
- LLNL `msr-safe`: [github.com/LLNL/msr-safe](https://github.com/LLNL/msr-safe)
