# C-States and Idle Management

## Table of Contents

1. [What Are C-States?](#1-what-are-c-states)
2. [Intel C-State Hierarchy](#2-intel-c-state-hierarchy)
3. [The cpuidle Subsystem](#3-the-cpuidle-subsystem)
4. [intel_idle vs ACPI cpuidle](#4-intel_idle-vs-acpi-cpuidle)
5. [PM QoS and Latency Constraints](#5-pm-qos-and-latency-constraints)
6. [How C-States Affect Overheating](#6-how-c-states-affect-overheating)
7. [Diagnosing and Tuning C-States](#7-diagnosing-and-tuning-c-states)

---

## 1. What Are C-States?

While P-states control CPU frequency/voltage while running, **C-states** control power when the CPU is idle. Each C-state represents a progressively deeper idle state with greater power savings but higher wake-up latency.

### State Transition

```
  RUNNING ──→ Idle ──→ C1 (Halt) ──→ C1E (Halt + lower voltage)
   ↑                    │
   │                    ▼
   │                  C6 (Deep power down)
   │                    │
   │                    ▼
   │                  C7-C10 (Package-level deep sleep)
   │                    │
Latency increase ───────┘
Power saving increase ↑
```

---

## 2. Intel C-State Hierarchy

### Per-Core C-States

| State | Instruction | Power Saving | Wake Latency | Description |
|---|---|---|---|---|
| C0 | — | None | — | Active |
| C1 | HLT/MWAIT(C1) | ~70% | ~1μs | Halt, clocks gated |
| C1E | MWAIT(C1) + low Vcc | ~80% | ~10μs | Halt + reduced voltage |
| C6 | MWAIT(C6) | ~90%+ | ~50-100μs | Core power gated, L1/L2 flushed |
| C7 | MWAIT(C7) | ~95%+ | ~100-200μs | Like C6 + more shared cache flushed |
| C8 | MWAIT(C8) | ~97%+ | ~200-300μs | Deeper package state |
| C9 | MWAIT(C9) | ~98%+ | ~500μs | Very deep |
| C10 | MWAIT(C10) | ~99%+ | ~1ms | Deepest, voltage rail off |

### Package C-States (PC-states)

When all cores are in deep C-states, the entire package can enter lower power states:

| State | Condition | Power Saving |
|---|---|---|
| PC2 | All cores in C2+ | ~50% package |
| PC3 | All cores in C3+ | ~70% package |
| PC6 | All cores in C6+ (plus uncore idled) | ~90% package |
| PC7-PC10 | All cores deep sleep + system ready | ~95%+ package |

### MWAIT Instruction

C-states are entered via the MWAIT (Monitor Wait) instruction, which takes a hint specifying the target C-state:

```asm
mov eax, 0x00    ; MWAIT(C1)
mov eax, 0x10    ; MWAIT(C1E)
mov eax, 0x20    ; MWAIT(C2)
mov eax, 0x30    ; MWAIT(C3)
mov eax, 0x50    ; MWAIT(C6, C7, C8 depending on implementation)
```

The kernel's idle loop executes MWAIT when there's no work to do.

---

## 3. The cpuidle Subsystem

### Architecture

```
CPU idle (no threads runnable)
  → cpuidle governor selects target C-state
    → menu governor (default): predicts idle duration
    → ladder governor (legacy): step-by-step
  → cpuidle driver executes MWAIT
  → Hardware enters C-state
  → Interrupt/NMI wakes CPU
  → cpuidle measures actual idle duration
  → Governor updates prediction model
```

### The menu Governor (Default)

The menu governor predicts how long the CPU will be idle based on:
- Timer events (next timer interrupt = guaranteed minimum)
- Recent history (average idle duration)
- PM QoS latency constraints

Decision pseudo-code:
```
predicted_us = predict_idle_duration()
latency_req = pm_qos_cpu_latency()

for state in c_states:
    if state.target_residency < predicted_us and
       state.exit_latency <= latency_req:
        select(state)
        break
```

---

## 4. intel_idle vs ACPI cpuidle

### intel_idle (Built-in driver)

- Uses MWAIT hints directly (known C-state tables per CPU model)
- Does NOT require ACPI tables
- Usually supports deeper C-states than ACPI
- Default on modern Intel CPUs since kernel 3.x

### ACPI cpuidle (acpi_idle)

- Falls back when intel_idle doesn't support the CPU
- Reads C-state information from ACPI `_CST` objects
- May support fewer states than intel_idle

### Checking Which Is Active

```bash
dmesg | grep -i "cpuidle\|intel_idle\|acpi_idle"
```

Our system with Tiger Lake should be using intel_idle.

---

## 5. PM QoS and Latency Constraints

PM QoS (Power Management Quality of Service) allows drivers to set latency constraints that prevent deep C-states. For example:

- A sound driver needs <2ms wake latency → prevents C10 (1ms latency)
- A network driver needs <100μs → prevents C6 (100μs)
- A PCIe device might need <10μs → prevents C1E

### Checking PM QoS Constraints

```bash
# CPU latency constraints
cat /sys/devices/system/cpu/cpu0/cpuidle/current_governor
cat /sys/devices/system/cpu/cpu0/cpuidle/state0/latency

# PM QoS interface
cat /sys/devices/power/pm_qos_resume_latency_us/
```

---

## 6. How C-States Affect Overheating

When the CPU can't enter deep C-states, it stays in shallower states consuming more power even when "idle". This contributes to baseline heat.

### Symptoms of Poor C-State Entry

1. CPU doesn't reach deep states (C6-C10) even when idle
2. Base power consumption elevated (measured via RAPL)
3. System runs warm at idle
4. Battery life reduced

### Common Causes of Shallow C-States

1. **Kernel tick**: `nohz_full` (adaptive-ticks) can reduce this
2. **Timer frequency**: `CONFIG_HZ=1000` → more wakeups vs `CONFIG_HZ=100`
3. **USB autosuspend**: External devices preventing deep sleep
4. **GPU activity**: Even idle GPU can block package C-states
5. **Network**: WiFi power management, background traffic
6. **NVMe/non-D0 devices**: Devices not in low-power states

### Checking C-State Residency

```bash
# Current C-state of each CPU
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/name
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/time
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/usage

# Total time per state
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  echo "=== $(basename $cpu) ==="
  cat "$cpu/cpuidle/state*/time" 2>/dev/null
done

# With turbostat (more readable)
turbostat --quiet --show C1,C1E,C6 --interval 5 2>/dev/null
```

---

## 7. Diagnosing and Tuning C-States

### Quick C-State Health Check

```bash
# Best tool: turbostat
turbostat --quiet --interval 10
# Look for C6 residency % and package power

# Or powertop
sudo powertop --csv=powertop.csv
```

### Raising Minimum C-State (for stability)

In rare cases, deep C-states cause system instability (particularly on laptops with buggy firmware):

```bash
# Kernel parameters to limit C-states
processor.max_cstate=1   # Prevents all but C1
processor.max_cstate=4   # Allows up to C4
intel_idle.max_cstate=4  # Limits intel_idle specifically
```

### Reducing Idle Power

```bash
# NixOS config to ensure good C-state entry
powerManagement.powertop.enable = true;  # Applies powertop --auto-tune

# USB autosuspend
services.power-profiles-daemon.enable = true;

# Network power saving
networking.networkmanager.wifi.powersave = true;
```

### References

- Intel SDM, Vol. 3B: Chapter 14.4 — C-States
- Linux kernel source: `drivers/cpuidle/cpuidle.c`
- Linux kernel source: `drivers/idle/intel_idle.c`
- Linux kernel source: `kernel/sched/idle.c`
- Arch Wiki: [CPU Frequency Scaling / C-States](https://wiki.archlinux.org/title/CPU_frequency_scaling)
