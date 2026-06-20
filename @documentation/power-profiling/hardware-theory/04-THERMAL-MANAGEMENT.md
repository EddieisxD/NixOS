# Thermal Management: Zones, Trip Points, and Daemons

## Table of Contents

1. [The Linux Thermal Subsystem](#1-the-linux-thermal-subsystem)
2. [Thermal Zones and Trip Points](#2-thermal-zones-and-trip-points)
3. [Cooling Devices](#3-cooling-devices)
4. [thermald: Intel Thermal Daemon](#4-thermald-intel-thermal-daemon)
5. [ACPI Thermal Management](#5-acpi-thermal-management)
6. [PowerClamp: Software Cooling](#6-powerclamp-software-cooling)
7. [Connecting to the Investigation](#7-connecting-to-the-investigation)
8. [Tuning thermald for Laptops](#8-tuning-thermald-for-laptops)

---

## 1. The Linux Thermal Subsystem

The Linux thermal subsystem is located in `drivers/thermal/` and provides:

1. **Thermal zone** — a temperature-controlled region (CPU package, GPU, battery, etc.)
2. **Thermal sensor** — a temperature sensor (DTS, ACPI, ADC, etc.)
3. **Cooling device** — a mechanism to reduce temperature (fan, CPU throttling, etc.)
4. **Thermal governor** — the algorithm that binds sensors to cooling devices
5. **Trip point** — a temperature threshold where cooling is activated

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Userspace (thermald)                     │
│  ┌─────────────┐  ┌───────────┐  ┌──────────────────┐   │
│  │ DPTF Extract │  │ XML Config│  │ D-Bus API        │   │
│  └──────┬──────┘  └─────┬─────┘  └────────┬─────────┘   │
└─────────┼───────────────┼──────────────────┼──────────────┘
          │               │                  │
┌─────────┼───────────────┼──────────────────┼──────────────┐
│         ▼               ▼                  ▼               │
│  ┌──────────────────────────────────────────────────┐     │
│  │              Thermal Sysfs Interface              │     │
│  │  /sys/class/thermal/                              │     │
│  └─────────┬─────────────┬──────────────┬───────────┘     │
│            │             │              │                  │
│  ┌─────────▼────┐ ┌──────▼──────┐ ┌─────▼──────────┐     │
│  │ Thermal Zones│ │Cooling Devs │ │Thermal Governors│     │
│  │ (thermal_zoneN)││ (cooling_deviceN)│ (step_wise, │     │
│  │             │ │             │ │  power_allocator,   │     │
│  │             │ │             │ │  user_space, etc.)  │     │
│  └─────────────┘ └─────────────┘ └────────────────┘     │
│                      Kernel Thermal Core                  │
└───────────────────────────────────────────────────────────┘
```

---

## 2. Thermal Zones and Trip Points

### Thermal Zones on Tiger Lake

Our system's thermal zones (from `/sys/class/thermal/`):

| Zone | Type | Temperature | Function |
|---|---|---|---|
| thermal_zone0 | INT3400 Thermal | 20°C | ACPI virtual zone (not a real temp sensor) |
| thermal_zone1 | acpitz | 42°C | ACPI temperature zone |
| thermal_zone2 | x86_pkg_temp | 42°C | CPU package DTS |
| thermal_zone3 | TCPU | 38°C | CPU temperature (PECI) |
| thermal_zone4 | iwlwifi_1 | 38°C | WiFi radio temperature |

### Trip Points

Each thermal zone can have trip points (temperature thresholds):

```bash
cat /sys/class/thermal/thermal_zone2/trip_point_0_temp
# 95000 (95°C — passive trip)
cat /sys/class/thermal/thermal_zone2/trip_point_0_type
# passive

cat /sys/class/thermal/thermal_zone2/trip_point_1_temp
# 100000 (100°C — critical trip)
cat /sys/class/thermal/thermal_zone2/trip_point_1_type
# critical
```

Trip types:
- **active**: Turn on/off cooling (e.g., fan control)
- **passive**: Throttle the device (reduce P-states)
- **hot**: Notify userspace, optional action
- **critical**: Emergency shutdown

### The Problem Without thermald

The default kernel thermal governor (`step_wise`) only acts at passive and critical trip points:

```
40°C → (nothing happens)
50°C → (nothing happens)
...
95°C → passive trip: reduce P-states
100°C → critical trip: emergency shutdown
```

That's a 55°C gap (40-95°C) with no thermal management. The kernel assumes something else (thermald) is managing the in-between range.

---

## 3. Cooling Devices

Cooling devices are mechanisms to extract heat or reduce heat generation:

| Device | Type | Mechanism | Path in sysfs |
|---|---|---|---|
| Processor | cpufreq | Reduce P-states | `/sys/class/thermal/cooling_device0/` |
| intel_powerclamp | idle injection | Force C1E state | `/sys/class/thermal/cooling_device1/` |
| Fan | fan | Increase airflow | `/sys/class/thermal/cooling_device2/` |
| Platform | ACPI | Various ACPI methods | Various |

### Checking Cooling Device Capabilities

```bash
cat /sys/class/thermal/cooling_device*/type
# Processor
# intel_powerclamp

cat /sys/class/thermal/cooling_device0/max_state
# 39 (matches num_pstates: 39 P-state levels)

cat /sys/class/thermal/cooling_device1/max_state
# 50 (50 levels of idle injection)
```

### How Cooling States Work

For the processor cooling device:
- `cur_state = 0` → No throttling (full P-state range available)
- `cur_state = 39` → Maximum throttling (lowest P-state only)

For intel_powerclamp:
- `cur_state = 0` → No idle injection
- `cur_state = 50` → CPU forced idle 50% of the time

---

## 4. thermald: Intel Thermal Daemon

`thermald` is Intel's userspace thermal management daemon. It provides the proactive thermal management that the kernel alone doesn't.

### Architecture

```
thermald
├── Main thread: temperature polling + decision loop
├── Configuration parser (thermal-conf.xml)
├── D-Bus interface (org.freedesktop.Thermal)
└── Sensor + Cooling device manager
```

### Detection and Auto-Configuration

On modern platforms, thermald:
1. Enumerates all thermal zones from `/sys/class/thermal/`
2. Reads ACPI thermal relationship tables (TRT, ART from DSDT)
3. Auto-generates a config file at `/etc/thermald/thermal-conf.xml.auto`
4. If DPTF (Dynamic Platform Thermal Framework) is available, uses it for fine-grained control

### Zero-Configuration Mode

Without any config file, thermald runs in "zero-config" mode:
- Monitors CPU package temperature via DTS
- Uses `intel_pstate` max_perf_pct to limit P-states
- Uses RAPL MSRs for power capping
- Uses PowerClamp as a last resort
- Default target temperature: varies by platform (~75-85°C)

### How thermald Makes Decisions

```
Loop:
  sensor_temp = read(thermal_zone/temp)
  target = get_target_temperature(sensor)
  error = sensor_temp - target
  
  if error > 0:
    // Too hot — engage cooling
    cooling_power = PID(error, integral, derivative)
    apply_cooling(cooling_power)
  else:
    // Cool enough — relax cooling
    apply_cooling(0)
```

The PID-based control prevents oscillation and smoothly adjusts cooling intensity.

### From the manpage:

> thermald monitors temperature and applies compensation using available cooling methods. By default, it monitors CPU temperature using available CPU digital temperature sensors and maintains CPU temperature under control, before HW takes aggressive correction action.

### Debugging thermald

```bash
# Run in foreground with debug logging
sudo thermald --no-daemon --loglevel=debug

# Check current thermald state
sudo thermctl status

# Read sysfs to see thermald's effects
watch -n 1 'cat /sys/devices/system/cpu/intel_pstate/max_perf_pct'
```

---

## 5. ACPI Thermal Management

### ACPI DSDT (Differentiated System Description Table)

The DSDT is a firmware table that describes the platform's thermal configuration:
- Thermal zones and their boundaries
- Trip point temperatures
- Cooling device bindings
- \_PSL (Passive) list — which CPUs are throttled
- \_AL0 (Active) — fan control
- \_CRT (Critical) — shutdown temperature

### Checking ACPI Thermal Configuration

```bash
# List ACPI thermal zones
ls /sys/firmware/acpi/thermal_zone*/

# Read the raw DSDT
sudo cat /sys/firmware/acpi/tables/DSDT > dsdt.dat
iasl -d dsdt.dat  # Decompile (requires acpica-tools)
```

### Common ACPI Thermal Bugs

1. **Uninitialized trip points**: As seen in a recent GitHub issue with Arrow Lake CPUs, some BIOS tables ship trip points at -274°C (0°K = uninitialized ACPI value), causing thermald to think the system is already overheating and engage maximum cooling immediately.

2. **No passive trip**: Some laptops omit passive trips, meaning the kernel never throttles until critical temperature.

3. **Wrong sensor bindings**: The DSDT may bind a cooling device to the wrong thermal zone.

---

## 6. PowerClamp: Software Cooling

The `intel_powerclamp` driver provides software-controlled cooling by injecting idle cycles. It works by:

1. Taking a CPU online and offline rapidly
2. Using MWAIT instructions to force C1E state
3. Generating heat-free idle time proportional to `cur_state / max_state`

This is the cooling method of last resort because:
- It wastes CPU time (reduces performance)
- It doesn't save energy (the CPU just idles instead of working)
- But it's guaranteed to work on any Intel CPU

### Relevant sysfs

```bash
/sys/class/thermal/cooling_device1/cur_state  # 0-50
```

---

## 7. Connecting to the Investigation

### Why Our System Overheats

```
Our system (without thermald):
  40°C ─── (idle, fine)
  Load ↑
  60°C ─── (getting warm, no action)
  70°C ─── (hot, no action)
  80°C ─── (very hot, no action)
  90°C ─── (fan screaming, no throttling action yet)
  95°C ─── passive trip → kernel throttles briefly
  100°C ── critical → shutdown risk

With thermald:
  40°C ─── (idle, fine)
  Load ↑
  60°C ─── thermald starts monitoring
  70°C ─── thermald sets max_perf_pct = 80%
  75°C ─── thermald sets max_perf_pct = 60%, RAPL limit = 45W
  80°C ─── equilibrium reached at target temperature
  Load ↓
  70°C ─── thermald relaxes to max_perf_pct = 100%
```

### The Fix

```nix
services.thermald.enable = true;
```

This single line change would install and enable thermald, which on Tiger Lake with zero configuration:
1. Monitors `x86_pkg_temp` (or an ACPI thermal zone)
2. Sets `intel_pstate/max_perf_pct` dynamically
3. Engages before passive trip points are reached
4. Smoothes temperature response using PID control

---

## 8. Tuning thermald for Laptops

While zero-config works, you can fine-tune for better fan noise / temperature balance:

### thermal-conf.xml

```xml
<?xml version="1.0"?>
<ThermalConfiguration>
  <Platform>
    <Name>ThinkPad X1 Extreme / Similar Laptop</Name>
    <ProductName>*</ProductName>
    <Preference>QUIET</Preference>  <!-- QUIET vs PERFORMANCE -->
    
    <ThermalSensors>
      <ThermalSensor>
        <Type>x86_pkg_temp</Type>
        <Path>/sys/class/thermal/thermal_zone2/</Path>
        <AsyncCapable>0</AsyncCapable>
      </ThermalSensor>
    </ThermalSensors>
    
    <ThermalZones>
      <ThermalZone>
        <Type>x86_pkg_temp</Type>
        <TargetTemperature>80000</TargetTemperature>  <!-- 80°C target -->
        <PID>  <!-- Proportional-Integral-Derivative control -->
          <Kp>300</Kp>
          <Ki>0</Ki>
          <Kd>0</Kd>
        </PID>
      </ThermalZone>
    </ThermalZones>
  </Platform>
</ThermalConfiguration>
```

### Key Knobs

| Parameter | Default | Effect |
|---|---|---|
| `TargetTemperature` | Platform-dependent | CPU target temp in °C (e.g., 80000 = 80°C) |
| `Preference` | `PERFORMANCE` | `PERFORMANCE` (lower latency) vs `QUIET` (lower fan) |
| `Kp` (proportional) | Platform-dependent | How aggressively to respond |
| `Ki` (integral) | Platform-dependent | How much to accumulate error |
| `Kd` (derivative) | Platform-dependent | How much to dampen response |

### Monitoring thermald

```bash
# Real-time temperature
watch -n 1 'cat /sys/class/thermal/thermal_zone*/temp'

# Real-time max performance %
watch -n 1 'cat /sys/devices/system/cpu/intel_pstate/max_perf_pct'

# Thermald specific
sudo journalctl -u thermald -f
```

### References

- Linux kernel source: `drivers/thermal/`
- thermald source: `https://github.com/intel/thermal_daemon`
- thermald manpage: `man thermald`
- Ubuntu Wiki: [Thermal Issues](https://wiki.ubuntu.com/Kernel/PowerManagement/ThermalIssues)
- GitHub issue demonstrating BIOS ACPI bugs: `github.com/intel/thermal_daemon/issues/550`
