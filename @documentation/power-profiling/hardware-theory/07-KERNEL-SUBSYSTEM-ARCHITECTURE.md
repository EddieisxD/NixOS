# Kernel Subsystem Architecture: The Full Power Management Stack

## Table of Contents

1. [Complete Architecture Diagram](#1-complete-architecture-diagram)
2. [Data Flow: How a Temperature Reading Becomes a Frequency Change](#2-data-flow-how-a-temperature-reading-becomes-a-frequency-change)
3. [Userspace ↔ Kernel Interactions](#3-userspace--kernel-interactions)
4. [All Relevant Kernel Source Files](#4-all-relevant-kernel-source-files)
5. [D-Bus Interface Landscape](#5-d-bus-interface-landscape)

---

## 1. Complete Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USERSPACE                                       │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────┐  ┌─────────────┐                │
│  │  power-profiles- │  │   thermald   │  │     TLP     │                │
│  │  daemon          │  │  (intel-     │  │  (laptop    │                │
│  │  (GNOME/freedesktop)│   thermal)   │  │   PM)      │                │
│  └────────┬─────────┘  └──────┬───────┘  └──────┬──────┘                │
│           │                   │                  │                       │
│  ┌────────┴─────────┐  ┌──────┴───────┐  ┌──────┴──────┐                │
│  │  auto-cpufreq    │  │  powercap    │  │  cpupower  │                │
│  │  (Python daemon) │  │  (userspace) │  │  (util)    │                │
│  └────────┬─────────┘  └──────┬───────┘  └──────┬──────┘                │
│           │                   │                  │                       │
│  ┌────────┴───────────────────┴──────────────────┴───────────┐          │
│  │                    SYSFS (/sys/)                           │          │
│  │  /sys/devices/system/cpu/cpu*/cpufreq/                    │          │
│  │  /sys/class/thermal/thermal_zone*/                        │          │
│  │  /sys/class/thermal/cooling_device*/                      │          │
│  │  /sys/devices/powercap/intel-rapl/                        │          │
│  │  /sys/bus/pci/devices/.../power/                          │          │
│  └────────────────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ sysfs read/write
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                           KERNEL                                         │
│                                                                          │
│  ┌──────────────────────────────────────────────────────┐               │
│  │              CPUFreq Core (cpufreq.c)                │               │
│  │  Policy management, sysfs interface, governor API    │               │
│  └────────┬──────────────┬──────────────────────────────┘               │
│           │              │                                              │
│  ┌────────▼──────┐  ┌────▼────────────┐                                │
│  │  intel_pstate  │  │ schedutil       │                                │
│  │  (intel/cmd)  │  │ governor        │                                │
│  │  active+passive│  │ (cfs-driven)   │                                │
│  └───────┬───────┘  └────┬────────────┘                                │
│          │               │                                              │
│          │               │  kernel/sched/cpufreq_schedutil.c            │
│          ▼               ▼                                              │
│  ┌──────────────────────────────────────────────────────┐               │
│  │               Intel P-state MSR interface            │               │
│  │       rdmsr/wrmsr (MSR_PERF_CTL, MSR_HWP_REQUEST)     │             │
│  └──────────────────────┬───────────────────────────────┘               │
│                         │                                              │
│  ┌──────────────────────▼───────────────────────────────┐               │
│  │               Thermal Subsystem (thermal/)            │               │
│  │  ┌─────────────┐  ┌────────────┐  ┌────────────────┐ │               │
│  │  │ Thermal Gov │  │Thermal Zone│  │Cooling Devices │ │               │
│  │  │ step_wise   │  │(zone/sensor)│  │ (cpufreq,     │ │               │
│  │  │ power_alloc │  │           │  │  powerclamp,   │ │               │
│  │  │ user_space  │  │           │  │  fan)          │ │               │
│  │  └─────────────┘  └────────────┘  └────────────────┘ │               │
│  └──────────────────────┬───────────────────────────────┘               │
│                         │                                              │
│  ┌──────────────────────▼───────────────────────────────┐               │
│  │               Power Capping (powercap/)               │               │
│  │       RAPL MSR driver (intel_rapl_msr.c)              │               │
│  │       Controls PL1/PL2 power limits                   │               │
│  └──────────────────────┬───────────────────────────────┘               │
│                         │                                              │
│  ┌──────────────────────▼───────────────────────────────┐               │
│  │               PCI Power Management                    │               │
│  │       pci_set_power_state() → D0/D3hot/D3cold        │               │
│  │       ACPI _PS0/_PS3 methods                          │               │
│  └───────────────────────────────────────────────────────┘               │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ MSR / MMIO / ACPI
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                           HARDWARE                                       │
│                                                                          │
│  ┌──────────────────────────────────────────────────────┐               │
│  │                CPU (Tiger Lake i7-11800H)            │               │
│  │  ┌──────────┐ ┌──────────┐ ┌──────┐ ┌───────────┐  │               │
│  │  │ P-state  │ │ C-state  │ │ RAPL │ │ DTS       │  │               │
│  │  │ Control  │ │ Control  │ │ Power│ │ Thermal   │  │               │
│  │  │ PCU      │ │ (MWAIT)  │ │ Limit│ │ Sensors   │  │               │
│  │  └──────────┘ └──────────┘ └──────┘ └───────────┘  │               │
│  └──────────────────────────────────────────────────────┘               │
│                                                                          │
│  ┌──────────────────────────────────────────────────────┐               │
│  │            NVIDIA RTX 3070 Laptop GPU                 │               │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────┐         │               │
│  │  │ P-states │ │ PCIe PM  │ │ RTD3 / D3cold│         │               │
│  │  └──────────┘ └──────────┘ └──────────────┘         │               │
│  └──────────────────────────────────────────────────────┘               │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Flow: How a Temperature Reading Becomes a Frequency Change

### Scenario: CPU gets hot under load

```
1. CPU CORE generates heat
       │
2. Digital Thermal Sensor (DTS) measures temperature
       │  ┌─ IA32_THERM_STATUS MSR (0x19C) for each core
       │  └─ IA32_PACKAGE_THERM_STATUS MSR (0x1B2) for package
       │
3. Kernel thermal subsystem reads DTS
       │  /sys/class/thermal/thermal_zone2/temp
       │  (thermal core: drivers/thermal/thermal_core.c)
       │
4. thermald polls thermal_zone
       │  (every poll_interval, default ~1-5s)
       │
5. thermald decides to cool
       │  error = temp - target_temp
       │  if error > 0 → engage cooling
       │
6. thermald writes RAPL power limit
       │  Method A: echo 45000000 > /sys/devices/powercap/intel-rapl/.../power_limit
       │  Method B: echo 60 > /sys/devices/system/cpu/intel_pstate/max_perf_pct
       │
7. Kernel enforces RAPL limit
       │  intel_rapl_msr.c writes MSR_PKG_POWER_LIMIT (0x610)
       │
8. CPU PCU responds to power limit
       │  Reduces P-states → lower frequency × lower voltage → less heat
       │
9. Temperature stabilizes
       │
10. thermald detects temperature drop → relaxes limit → loop continues
```

---

## 3. Userspace ↔ Kernel Interactions

### Interfaces

| Interface | Location | Used By | Example |
|---|---|---|---|
| sysfs (cpufreq) | `/sys/devices/system/cpu/cpu*/cpufreq/` | cpupower, PPD, TLP | Write governor, min/max freq |
| sysfs (thermal) | `/sys/class/thermal/` | thermald | Read temp, set cooling state |
| sysfs (powercap) | `/sys/devices/powercap/` | thermald, TLP | Set RAPL power limits |
| sysfs (intel_pstate) | `/sys/devices/system/cpu/intel_pstate/` | cpupower, thermald | Set max/min performance % |
| sysfs (PCI PM) | `/sys/bus/pci/devices/.../power/` | TLP | PCI power control |
| D-Bus (UPower) | `org.freedesktop.UPower.PowerProfiles` | PPD, GNOME, KDE | Switch power profiles |
| D-Bus (thermald) | `org.freedesktop.Thermal` | thermctl, monitoring apps | Query thermal state |
| MSR | `/dev/cpu/*/msr` | rdmsr/wrmsr, turbostat, thermald | Direct register access |
| netlink | Kernel → userspace | thermald (via thermal netlink) | Async thermal events |

### Security

- **sysfs**: Writing to power/thermal sysfs requires root
- **MSR**: Requires `CAP_SYS_RAWIO` or root
- **D-Bus**: PPD allows unprivileged profile switching (via polkit)
- **power-profiles-daemon**: The daemon runs as root but exposes a D-Bus API accessible to users via polkit

---

## 4. All Relevant Kernel Source Files

| Subsystem | File(s) | Path in kernel tree |
|---|---|---|
| cpufreq core | `cpufreq.c`, `cpufreq_governor.c` | `drivers/cpufreq/` |
| intel_pstate driver | `intel_pstate.c` | `drivers/cpufreq/` |
| schedutil governor | `cpufreq_schedutil.c` | `kernel/sched/` |
| PELT tracking | `pelt.h`, `fair.c` | `kernel/sched/` |
| Thermal core | `thermal_core.c`, `thermal_sysfs.c` | `drivers/thermal/` |
| Thermal governors | `gov_step_wise.c`, `gov_power_allocator.c` | `drivers/thermal/` |
| intel_powerclamp | `intel_powerclamp.c` | `drivers/thermal/intel/` |
| intel_rapl_msr | `intel_rapl_msr.c` | `drivers/powercap/` |
| intel_rapl_common | `intel_rapl_common.c` | `drivers/powercap/` |
| cpuidle core | `cpuidle.c`, `cpuidle-pseries.c` | `drivers/cpuidle/` |
| intel_idle | `intel_idle.c` | `drivers/idle/` |
| PCI PM | `pci.c` (pci_set_power_state) | `drivers/pci/` |
| NVidia driver | `nvidia.ko` (proprietary) | External; in DMES |
| nvidia-persistenced | Userspace daemon | NVIDIA package |
| MSR device | `msr.c` | `drivers/char/` |

---

## 5. D-Bus Interface Landscape

### UPower PowerProfiles (org.freedesktop.UPower.PowerProfiles)

Used by `power-profiles-daemon` and read by desktop environments:

```dbus
interface org.freedesktop.UPower.PowerProfiles {
    readonly property s ActiveProfile;
    readonly property as Profiles;
    method void HoldProfile(s profile, s reason, u duration);
    method void ReleaseProfile(s reason);
    signal void ProfileReleased(s reason);
};
```

### thermald D-Bus (org.freedesktop.Thermal)

```dbus
interface org.freedesktop.Thermal {
    method void GetTemperature();
    method void GetCoolingDevices();
    signal void TemperatureChanged(d temperature);
};
```

### How noctalia Fits In

Noctalia reads the UPower PowerProfiles D-Bus interface through Quickshell's built-in `UPower` service. It does NOT bypass or override any kernel-level settings — it's a UI layer on top of the existing D-Bus API.

### References

- kernel source tree: [drivers/cpufreq/](https://github.com/torvalds/linux/tree/master/drivers/cpufreq)
- kernel source tree: [drivers/thermal/](https://github.com/torvalds/linux/tree/master/drivers/thermal)
- kernel source tree: [drivers/powercap/](https://github.com/torvalds/linux/tree/master/drivers/powercap)
- FDO specification: [UPower PowerProfiles](https://gitlab.freedesktop.org/upower/power-profiles-daemon)
