# BIOS / UEFI / ACPI Role in Power Management

## Table of Contents

1. [The Firmware's Role](#1-the-firmwares-role)
2. [ACPI Tables for Power Management](#2-acpi-tables-for-power-management)
3. [CPPC: Collaborative Processor Performance Control](#3-cppc-collaborative-processor-performance-control)
4. [DPTF: Dynamic Platform Thermal Framework](#4-dptf-dynamic-platform-thermal-framework)
5. [The _OSC Method](#5-the-osc-method)
6. [Common BIOS Settings and Their Effects](#6-common-bios-settings-and-their-effects)
7. [How to Debug ACPI Power Issues](#7-how-to-debug-acpi-power-issues)

---

## 1. The Firmware's Role

The BIOS/UEFI firmware initializes the hardware and hands control to the OS via ACPI. In the context of power management, the firmware:

1. **Enables/disables features**: HWP, C-states, P-states, turbo boost
2. **Defines thermal zones**: DSDT table specifies sensors, trip points, and cooling devices
3. **Exposes power limits**: PL1, PL2, Tau, and whether they're configurable
4. **Provides CPPC interface**: For HWP-like control on some platforms
5. **Manages GPU power**: PCIe hotplug and D3cold support

### What the Firmware Controls

| Feature | BIOS Setting | ACPI Object | Kernel Impact |
|---|---|---|---|
| HWP | "Intel Speed Shift" / "HWP" | _OSC | intel_pstate mode |
| Turbo | "Turbo Mode" / "Intel Turbo Boost" | _PPC | no_turbo sysfs |
| C-states | "C-States" / "Power Technology" | _CST | cpuidle states |
| PL1/PL2 | "Turbo Power Limit" | N/A (MSR) | RAPL constraints |
| GPU D3cold | "NVIDIA GPU Power Management" | _PS0/_PS3 | RTD3 support |

---

## 2. ACPI Tables for Power Management

### DSDT (Differentiated System Description Table)

The DSDT is the primary ACPI table that describes the platform's power management capabilities. Key objects:

| Object | Purpose |
|---|---|
| `_PSS` | Supported P-states (frequency, power, transition latency) |
| `_PPC` | Performance Present Capabilities (what P-states are currently allowed) |
| `_PSD` | P-state dependency (which CPUs share voltage rail) |
| `_CPC` | Continuous Performance Control (CPPC interface) |
| `_CST` | C-state information |
| `_TC1`/_TC2` | Thermal control parameters |
| `_TSP` | Thermal sampling period |
| `_PSV` | Passive trip point temperature |
| `_CRT` | Critical trip point temperature |
| `_AC0`-`_AC9` | Active cooling (fan) trip points |
| `_AL0` | Active cooling device list (fans) |
| `_PSL` | Passive cooling device list (CPUs to throttle) |

### Reading ACPI Tables

```bash
# Dump all ACPI tables
cat /sys/firmware/acpi/tables/DSDT > dsdt.dat

# Decompile (requires acpica-tools)
iasl -d dsdt.dat

# View specific objects
grep -i "_PSV\|_CRT\|_AC0" dsdt.dsl
```

### SSDT (Secondary System Description Table)

Often contains additional power management data, especially for OEM-specific features.

```bash
for t in /sys/firmware/acpi/tables/SSDT*; do
  echo "=== $(basename $t) ==="
  cat "$t" | iasl -d 2>/dev/null | grep -i "power\|thermal\|pstate\|cstate" | head -5
done
```

---

## 3. CPPC: Collaborative Processor Performance Control

CPPC is an ACPI interface for HWP-like functionality. It's defined in ACPI 6.0+ and is used by Intel and AMD.

### CPPC Registers (in ACPI _CPC object)

| Register | Description |
|---|---|
| `HighestPerformance` | Maximum performance level |
| `NominalPerformance` | Guaranteed performance (base freq) |
| `LowestNonlinearPerformance` | Most efficient point |
| `LowestPerformance` | Minimum performance |
| `DesiredPerformance` | OS requests specific performance |
| `MinimumPerformance` | OS-specified minimum |
| `MaximumPerformance` | OS-specified maximum |
| `EnergyPerformancePreference` | EPP hint |
| `GuaranteedPerformanceRegister` | Notifies OS of cap changes |
| `ReferencePerformanceCounter` | For performance measurement |
| `ReferencePerformanceFrequency` | For frequency calculation |

### CPPC vs HWP

Both serve the same purpose (hardware-controlled P-states), but:
- HWP uses MSRs directly (faster, lower overhead)
- CPPC uses ACPI described registers (can be MMIO or shared memory)
- On Intel systems with HWP, the kernel uses HWP MSRs directly, bypassing CPPC
- On AMD systems, CPPC is the primary interface

---

## 4. DPTF: Dynamic Platform Thermal Framework

DPTF is Intel's firmware-level thermal management framework. It provides:

1. **TRT (Thermal Relationship Table)**: Maps temperature sensors to cooling devices
2. **ART (Active Relationship Table)**: Fan speed vs temperature curves
3. **Policy**: Temperature targets, hysteresis, and priorities

### How DPTF Interacts with thermald

thermald reads TRT/ART from ACPI and can use them for thermal management. On systems with DPTF:
- thermald auto-generates a config file (`thermal-conf.xml.auto`)
- DPTF handles fan control (EC-based)
- thermald handles CPU throttling (P-state/RAPL based)

### Checking for DPTF

```bash
cat /sys/firmware/acpi/tables/DSDT | strings | grep -i "DPTF\|TRT\|ART"
```

---

## 5. The _OSC Method

The `_OSC` (Operating System Capabilities) method is called by the OS during boot to negotiate capabilities with the firmware:

```acpi
Method(_OSC, 4, NotSerialized)
{
  // The OS tells firmware: "I can support these features"
  // Firmware responds: "I grant you this subset"
  // Arguments:
  //   Arg0 = UUID of feature set
  //   Arg1 = Revision
  //   Arg2 = Counters
  //   Arg3 = Capabilities bitmask
}
```

### Relevant UUIDs

| UUID | Feature |
|---|---|
| `0811B06E-4A27-44F9-8D60-3CB2BC6B2A1E` | Processor Power Management |
| `E5C937D0-3557-4D4A-BD7D-9B3D5E5F5B5A` | Graphics / Display |

If the OS doesn't negotiate processor power management via _OSC, the firmware may:
- Disable HWP
- Disable deeper C-states
- Limit P-state range

---

## 6. Common BIOS Settings and Their Effects

| BIOS Setting | Effect on Linux | Recommendation for Overheating |
|---|---|---|
| **Intel Speed Shift (HWP)** | Enables HWP → active mode intel_pstate → EPP, better thermal response | **Enable** |
| **Turbo Mode** | Allows CPU to exceed base frequency | **Disable on battery**, consider enabling on AC |
| **C-States** | Enables deep idle power saving | **Enable** (C1E, C6, C10) |
| **Power Technology** | Custom/Maximum/Minimum power configuration | **Custom** → tune PL1/PL2 |
| **CPU Flex Ratio Override** | Override default frequency limits | **Disable** (keep defaults) |
| **VR Current Limit** | Voltage regulator current cap | Keep default (too low = throttling) |
| **NVIDIA GPU Power State** | Controls GPU power management | **Enable RTD3** if available |
| **Hyper-Threading** | SMT on/off | Keep enabled (disabled = lower peak heat but less performance) |

### How to Change BIOS Settings

1. Reboot and press F2/F10/Del (varies by manufacturer) during POST
2. Look for "Advanced" or "Power" or "CPU Configuration" menus
3. Specific settings vary by OEM:
   - Dell: "Power Management" → "Intel Speed Shift"
   - Lenovo: "Config" → "Power" → "Intel Speed Shift"
   - ASUS: "Advanced" → "CPU Configuration" → "Intel Speed Shift"
   - MSI: "OC" → "CPU Features" → "Intel Speed Shift"

---

## 7. How to Debug ACPI Power Issues

### Kernel Messages

```bash
# Check for ACPI errors
dmesg | grep -i "acpi.*error\|acpi.*fail"
dmesg | grep -i "intel_pstate\|cppc\|p-state"
dmesg | grep -i "thermal\|trip\|throttle"

# Check for _OSC negotiation
dmesg | grep -i "osc"
```

### ACPI Device Hierarchy

```bash
# List ACPI power resources
ls /sys/devices/LNXSYSTM:00/LNXSYBUS:00/

# Check specific device power states
find /sys/devices -name "power_state" -exec echo "{}: $(cat {})" \; 2>/dev/null
```

### Check if GPU RTD3 Is Supported

```bash
# NVIDIA GPU PCI ID
lspci | grep -i nvidia

# Check PCI power management
cat /sys/bus/pci/devices/0000:01:00.0/power/control  # "auto" if PM enabled
cat /sys/bus/pci/devices/0000:01:00.0/power/state    # D0 if powered on

# Check for D3cold support
cat /proc/driver/nvidia/gpus/0000:01:00.0/power
```

### References

- ACPI Specification 6.5: [UEFI.org](https://uefi.org/specifications)
- Intel SDM, Vol. 3B: Chapter 14 — Platform power management
- Linux kernel source: `drivers/acpi/processor_perflib.c` (P-state via ACPI)
- Linux kernel source: `drivers/acpi/processor_idle.c` (C-states via ACPI)
