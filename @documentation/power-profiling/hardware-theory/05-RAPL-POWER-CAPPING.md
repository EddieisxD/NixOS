# RAPL: Running Average Power Limit

## Table of Contents

1. [What Is RAPL?](#1-what-is-rapl)
2. [RAPL Domains](#2-rapl-domains)
3. [RAPL MSRs](#3-rapl-msrs)
4. [The powercap Sysfs Interface](#4-the-powercap-sysfs-interface)
5. [How thermald and TLP Use RAPL](#5-how-thermald-and-tlp-use-rapl)
6. [Configuring Power Limits](#6-configuring-power-limits)
7. [RAPL in the Tiger Lake System](#7-rapl-in-the-tiger-lake-system)

---

## 1. What Is RAPL?

RAPL (Running Average Power Limit) is a hardware feature introduced with Intel Sandy Bridge (2nd gen) that allows software to set power consumption limits on various CPU domains. The CPU's internal PCU (Power Control Unit) then enforces these limits by adjusting P-states, C-states, and clock speeds.

RAPL provides two capabilities:
1. **Power limiting**: Set a maximum power budget that the CPU/DRAM cannot exceed
2. **Energy metering**: Read accumulated energy consumption counters

### Why RAPL Matters for Overheating

RAPL is NOT a thermal management feature — it's a power management feature. However, power correlates strongly with temperature:
- **PL1 (Power Limit 1)**: Long-term power limit (sustained), typically equals the CPU's TDP
- **PL2 (Power Limit 2)**: Short-term power limit (turbo boost), time-limited by Tau
- **PL3**: Peak power limit (discrete GPU or server SKUs)

Setting PL1 to the CPU's TDP (e.g., 45W for the i7-11800H) ensures the CPU doesn't exceed its thermal design power, which means it won't generate more heat than the cooling solution can handle.

---

## 2. RAPL Domains

Intel CPUs expose multiple RAPL domains:

| Domain | MSR | Scope | Measures |
|---|---|---|---|
| **Package (PKG)** | 0x610, 0x611 | Entire CPU package | All cores + uncore |
| **Power Plane 0 (PP0)** | 0x638, 0x639 | All CPU cores | Core power only |
| **Power Plane 1 (PP1)** | 0x641 | Graphics | iGPU power |
| **DRAM** | 0x618, 0x619 | System RAM | Memory power |
| **Platform (PSys)** | 0x6C0 (some platforms) | Entire SoC | CPU + memory + PCH |

On Tiger Lake-H (mobile), typically PKG and DRAM domains are available.

---

## 3. RAPL MSRs

### Power Limit MSR Format (MSR_PKG_POWER_LIMIT, 0x610)

```
Bit 0-14:   Power Limit 1 (PL1) in 1/8 Watt units
Bit 15:     PL1 Enable (1 = enabled)
Bit 16:     PL1 Clamping (1 = allow going below current limit)
Bit 17-20:  Time Window 1 (Tau) — 2^(Y) × (1+X/4) × 1/4 second
Bit 21-22:  Time Window unit
Bit 23:     Reserved
Bit 24-38:  Power Limit 2 (PL2) in 1/8 Watt units
Bit 39:     PL2 Enable
Bit 40:     PL2 Clamping
Bit 41-44:  Time Window 2
Bit 45-46:  Reserved
Bit 47:     Lock bit (if set, MSR cannot be changed until reboot)
Bit 48-63:  Reserved
```

### Energy Status MSR (MSR_PKG_ENERGY_STATUS, 0x611)

A monotonically increasing counter of energy consumed, in microjoules. The unit is read from MSR_RAPL_POWER_UNIT (0x606):

```
Bits 0-3:   Power unit (typically 1/8 W = 0.125W per LSB)
Bits 4-7:   Reserved
Bits 8-12:  Energy unit (typically 1/65536 J = ~15.3 μJ per LSB)
Bits 13-16: Time unit (typically 1/976.56 μs per LSB)
```

### Reading RAPL on Linux

```bash
# Install msr tools
sudo modprobe msr

# Read package energy
sudo rdmsr -d 0x611  # Decimal value (incrementing counter)

# Read power limit
sudo rdmsr -d 0x610  # Decimal

# Parse power limit: value × 0.125 = watts
sudo rdmsr -x -f 14:0 0x610  # Extract PL1 value in hex
```

---

## 4. The powercap Sysfs Interface

The `powercap` subsystem provides a safer interface to RAPL than raw MSR access:

```bash
ls /sys/devices/powercap/intel-rapl/
```

Typical structure:
```
intel-rapl/
├── intel-rapl:0/           # Package domain
│   ├── name                # "package-0"
│   ├── max_energy_range_uj # Maximum energy counter value
│   ├── energy_uj           # Current energy counter
│   ├── power_uw            # Current power (updated periodically)
│   ├── constraint_0_max_power_uw  # PL1 max power
│   ├── constraint_0_power_limit_uw # PL1 current limit
│   ├── constraint_0_time_window_us # PL1 tau
│   └── constraint_1_*              # PL2
├── intel-rapl:1/           # Core domain (PP0)
│   └── ...
├── intel-rapl:2/           # Uncore domain (PP1 or GT)
│   └── ...
└── intel-rapl:3/           # DRAM domain
    └── ...
```

### Reading Power Consumption

```bash
# Energy consumption (accumulated μJ)
cat /sys/devices/powercap/intel-rapl/intel-rapl:0/energy_uj

# Current power consumption in microwatts
cat /sys/devices/powercap/intel-rapl/intel-rapl:0/power_uw

# PL1 power limit in microwatts
cat /sys/devices/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
```

### Setting Power Limits

```bash
# Set PL1 to 45W (45000000 μW)
echo 45000000 | sudo tee /sys/devices/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
```

---

## 5. How thermald and TLP Use RAPL

### thermald + RAPL

`thermald` uses RAPL as one of its cooling mechanisms:
1. When temperature exceeds target, writes a lower PL1 value
2. This limits the maximum sustained power draw
3. The PCU enforces the limit by reducing P-states
4. Temperature stabilizes as power is capped

thermald writes to the `powercap` sysfs (or directly to MSRs if needed).

### TLP + RAPL

TLP can set RAPL limits statically:
```nix
# In TLP config:
CPU_POWER_LIMIT_PL1_ON_AC = 45
CPU_POWER_LIMIT_PL2_ON_AC = 60
CPU_POWER_LIMIT_PL1_ON_BAT = 25
CPU_POWER_LIMIT_PL2_ON_BAT = 45
```

### The Difference

| Tool | PL1 behavior | Why |
|---|---|---|
| thermald | Dynamic (adjusts based on temp) | Thermal management |
| TLP | Static (fixed per AC/battery) | Power saving |

---

## 6. Configuring Power Limits

### For the Tiger Lake i7-11800H

The i7-11800H has:
- TDP: 45W (configurable up to 65W by OEM)
- PL2 (turbo): Usually 107W for ~28 seconds
- Tau: The PL2 time window (often 28-56 seconds)

Default values can be checked:
```bash
cat /sys/devices/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
# 45000000 (45W)

cat /sys/devices/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw
# 107000000 (107W)

cat /sys/devices/powercap/intel-rapl/intel-rapl:0/constraint_1_time_window_us
# 28000000 (28 seconds)
```

### Suggested Limits for Overheating Laptop

```nix
services.power-profiles-daemon.enable = true;
# In power-saver mode, PPD can set conservative RAPL limits
```

Or with TLP:
```nix
services.tlp.enable = true;
# Set in /etc/tlp.conf
# CPU_POWER_LIMIT_PL1_ON_BAT = 25
# CPU_POWER_LIMIT_PL2_ON_BAT = 45
```

---

## 7. RAPL in the Tiger Lake System

RAPL is available and active in our system (confirmed by `intel-rapl` sysfs):
- PKG domain: Package 0 (CPU + uncore)
- DRAM domain: System memory

The default PL1 and PL2 values depend on the laptop OEM's firmware configuration. Some laptop manufacturers set very aggressive PL2 values (107W+ on a 45W TDP CPU), which allows the CPU to draw massive power briefly — generating a lot of heat that the cooling system must absorb.

Without thermald actively managing RAPL limits, the CPU can freely boost to PL2 limits, and when the time window expires, the temperature spikes must be handled by thermal mass alone.

### References

- Intel SDM, Vol. 3B: Chapter 14.7 — RAPL
- Intel SDM, Vol. 4: MSR listings (MSR_PKG_POWER_LIMIT, etc.)
- Linux kernel source: `drivers/powercap/intel_rapl_msr.c`, `drivers/powercap/intel_rapl_common.c`
- kernel-internals.org: [Power Capping and RAPL](https://kernel-internals.org/power/power-capping)
