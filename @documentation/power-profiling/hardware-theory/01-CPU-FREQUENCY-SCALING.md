# CPU Frequency Scaling: P-States and the cpufreq Subsystem

## Table of Contents

1. [P-States: The Hardware Reality](#1-p-states-the-hardware-reality)
2. [The cpufreq Subsystem Architecture](#2-the-cpufreq-subsystem-architecture)
3. [Scaling Governors](#3-scaling-governors)
4. [Scaling Drivers](#4-scaling-drivers)
5. [Sysfs Interface](#5-sysfs-interface)
6. [How schedutil Works (Deep Dive)](#6-how-schedutil-works-deep-dive)
7. [Impact on Thermal Behavior](#7-impact-on-thermal-behavior)

---

## 1. P-States: The Hardware Reality

### What Is a P-State?

A **P-state** (Performance State) is an operational (frequency, voltage) pair that a CPU core can operate at. The set of available P-states is defined by the hardware and is typically enumerated during CPU initialization.

Modern Intel CPUs have a P-state range like:

| Name | Freq Range | Description |
|---|---|---|
| P0 | ~4.6 GHz | Maximum turbo frequency (one core, favorable conditions) |
| P1 | ~2.3 GHz | Base frequency (guaranteed, all cores) |
| P2-Pn | Graduated steps | Intermediate frequencies |
| PN | ~800 MHz | Minimum frequency (lowest voltage) |

On the Tiger Lake i7-11800H in this system:
```bash
cat /sys/devices/system/cpu/intel_pstate/num_pstates
# 39 (meaning 39 discrete P-state points from min to max)
```

### Key Hardware Properties

1. **Voltage-Frequency Relationship**: Power ∝ C × V² × f (approximately). Reducing frequency allows reducing voltage, giving cubic-like power savings at lower P-states.
2. **P-State transitions are not free**: Each transition takes time (~10-20μs on modern CPUs) and consumes energy. This is why rate-limiting exists.
3. **Turbo**: P0 frequencies above the base frequency are "turbo" states. They use more voltage and are thermally constrained — the CPU can only sustain them briefly or with some cores idle.

### How P-States Are Controlled

There are two mechanisms:

1. **Legacy (OS-controlled)**: The OS writes to MSRs (specifically MSR_PERF_CTL, 0x199) to request a specific P-state. The CPU's power control unit (PCU) then transitions voltage and frequency.

2. **HWP (Hardware-Controlled)**: The OS provides a performance range (min and max, via MSR_HWP_REQUEST, 0x774) and an energy performance preference hint. The CPU's PCU autonomously selects P-states within this range based on workload and thermal conditions.

### MSR Registers for P-State Control

| MSR | Address | Function |
|---|---|---|
| MSR_PERF_CTL | 0x199 | Legacy P-state request |
| MSR_PERF_STATUS | 0x198 | Current P-state (read-only) |
| MSR_HWP_REQUEST | 0x774 | HWP request (min, max, desired, EPP) |
| MSR_HWP_CAPABILITIES | 0x771 | HWP capabilities (read-only) |
| MSR_HWP_STATUS | 0x777 | HWP status (read-only) |
| MSR_PKG_POWER_LIMIT | 0x610 | RAPL package power limit |
| MSR_PP0_POWER_LIMIT | 0x638 | RAPL core power limit |
| MSR_PP1_POWER_LIMIT | 0x641 | RAPL graphics power limit |
| MSR_DRAM_POWER_LIMIT | 0x618 | RAPL DRAM power limit |

### Reading MSRs on Linux

```bash
# Requires msr kernel module and root
sudo modprobe msr
sudo rdmsr -a 0x198   # Read PERF_STATUS on all cores
sudo rdmsr -a 0x771   # Read HWP_CAPABILITIES on all cores
```

---

## 2. The cpufreq Subsystem Architecture

The Linux kernel's CPU frequency scaling subsystem is organized in layers:

```
Userspace Tools
  (cpupower, power-profiles-daemon, thermald, TLP, acpid, etc.)
       │
       ▼  sysfs interface (/sys/devices/system/cpu/cpu*/cpufreq/)
┌──────────────┐
│  cpufreq core │  ← Policy management, governor registration, sysfs
│  (driver/cpufreq/cpufreq.c)  │
└──────┬───────┘
       │
       ├─── Scaling Governor (algorithm)
       │    ├── performance       (always max frequency)
       │    ├── powersave         (always min frequency)
       │    ├── userspace         (manual control via sysfs)
       │    ├── ondemand          (load-based, periodic sampling)
       │    ├── conservative      (ondemand but smoother transitions)
       │    └── schedutil         (scheduler-integrated, PELT-based)
       │
       └─── Scaling Driver (hardware interface)
            ├── intel_pstate      (Intel, active mode + HWP)
            ├── intel_cpufreq     (Intel, passive mode)
            ├── amd_pstate        (AMD)
            ├── acpi-cpufreq      (Generic ACPI)
            └── (others: qcom-cpufreq, ti-cpufreq, etc.)
```

### Key Source Files in the Kernel

| File | Role |
|---|---|
| `kernel/sched/cpufreq_schedutil.c` | schedutil governor implementation |
| `drivers/cpufreq/intel_pstate.c` | intel_pstate scaling driver |
| `drivers/cpufreq/cpufreq.c` | cpufreq core |
| `drivers/cpufreq/cpufreq_governor.c` | Governor base infrastructure |
| `kernel/sched/pelt.h` | PELT utilization tracking |

---

## 3. Scaling Governors

### performance

Always selects the highest available P-state.

- **Behavior**: Static — frequency stays at max regardless of load
- **Use case**: Benchmarking, latency-sensitive workloads
- **Power cost**: Maximum — no idle power benefit
- **Thermal impact**: Maximum heat generation

```bash
# Set all CPUs to performance governor
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### powersave

Always selects the lowest available P-state.

- **Behavior**: Static — frequency stays at min regardless of load
- **Use case**: Low-power background tasks, thermal emergencies
- **Paradox**: Under sustained load, a slow CPU works longer + harder, potentially consuming more power than a faster CPU that finishes quickly and sleeps
- **Thermal impact**: Lowest peak temperature, but potential for prolonged heat under sustained load

### schedutil

The scheduler-integrated governor (covered in depth in [Section 6](#6-how-schedutil-works-deep-dive)).

### ondemand

The classic dynamic governor. Periodically samples CPU utilization and adjusts frequency.

- **Sample rate**: Configurable (default ~10ms = `sampling_rate`, but rate-limited to `min_sampling_rate` = `1/2 * transition_latency`)
- **Algorithm**: If utilization > `up_threshold` (default 80%), ramp up; if below, ramp down gradually
- **Down differential**: `sampling_down_factor` controls how conservatively to scale down
- **Legacy**: The old standard; largely replaced by schedutil on modern systems

```bash
# Check ondemand parameters
ls /sys/devices/system/cpu/cpufreq/ondemand/
```

### conservative

Similar to ondemand but with smoother transitions:
- Steps up/down one P-state at a time (instead of jumping to max)
- `freq_step` (default 5%) controls step size
- Less aggressive, slower to respond to load spikes

### userspace

Allows manual frequency selection via sysfs:
```bash
echo userspace | tee .../scaling_governor
echo 2300000 | tee .../scaling_setspeed  # Set to 2.3 GHz
```

---

## 4. Scaling Drivers

### intel_pstate (Active Mode)

- **scaling_driver**: "intel_pstate"
- **Available governors**: `powersave`, `performance` (note: these are Intel-specific variants!)
- **Behavior**: Bypasses the generic governor layer entirely
  - With HWP: Delegates to CPU hardware
  - Without HWP: Uses internal algorithm (similar to schedutil)
- **Intel-specific knobs**: `min_perf_pct`, `max_perf_pct`, `no_turbo`, `energy_performance_preference`

### intel_cpufreq (Passive Mode)

- **scaling_driver**: "intel_cpufreq"
- **Available governors**: All generic governors (`schedutil`, `performance`, `powersave`, `ondemand`, `conservative`, `userspace`)
- **Behavior**: Standard cpufreq driver that translates governor requests to Intel pstate MSR writes
- **Used when**: HWP not available, or `intel_pstate=passive` kernel parameter set

### Distinction Example

On our system, `intel_pstate` is in passive mode, so `intel_cpufreq` is the active driver:

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
# intel_cpufreq

cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
# performance schedutil
```

If HWP were active, we'd see:
```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
# intel_pstate

cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
# performance powersave
```

---

## 5. Sysfs Interface

The cpufreq sysfs interface is at `/sys/devices/system/cpu/cpu*/cpufreq/` for each CPU.

### Per-Policy Files

| File | Description | Values |
|---|---|---|
| `scaling_governor` | Current governor | `performance`, `powersave`, `schedutil`, etc. |
| `scaling_available_governors` | Available governors | List |
| `scaling_cur_freq` | Current frequency (kHz) | Integer |
| `scaling_max_freq` | Maximum frequency limit (kHz) | Integer |
| `scaling_min_freq` | Minimum frequency limit (kHz) | Integer |
| `scaling_driver` | Driver name | String |
| `scaling_setspeed` | Target frequency (userspace governor) | kHz |
| `affected_cpus` | CPUs in this policy | List |
| `related_cpus` | CPUs sharing same voltage rail | List |
| `cpuinfo_min_freq` | Hardware minimum (kHz) | Integer |
| `cpuinfo_max_freq` | Hardware maximum (kHz) | Integer |
| `cpuinfo_transition_latency` | Transition latency (ns) | Integer |
| `energy_performance_preference` | EPP hint (HWP only) | String or 0-255 |

### Global intel_pstate Files

| File | Description | Values |
|---|---|---|
| `/sys/devices/system/cpu/intel_pstate/max_perf_pct` | Max performance % | 0-100 |
| `/sys/devices/system/cpu/intel_pstate/min_perf_pct` | Min performance % | 0-100 |
| `/sys/devices/system/cpu/intel_pstate/no_turbo` | Disable turbo | 0/1 |
| `/sys/devices/system/cpu/intel_pstate/num_pstates` | Number of P-states | Integer |
| `/sys/devices/system/cpu/intel_pstate/turbo_pct` | Turbo range % | Integer |
| `/sys/devices/system/cpu/intel_pstate/status` | Operation mode | active/passive/off |

---

## 6. How schedutil Works (Deep Dive)

`schedutil` is unique among governors because it's integrated directly into the CFS scheduler rather than running as a separate timer-based polling loop.

### PELT (Per-Entity Load Tracking)

The foundation of schedutil is PELT, which tracks utilization for each scheduling entity (task or runqueue):

```
PELT decay chain (half-life = 32ms):
util_{n+1} = util_n × 0.5^(period/32ms) + running_time/period

Period = 1024μs (the scheduler tick on CONFIG_HZ=1000)
```

The key insight is that PELT tracks **utilization**, not load — it's the fraction of time the entity was actually running.

### Frequency Scale Invariance

On x86, the raw PELT signal is NOT frequency-invariant by default. This means:
- If the CPU runs at 50% frequency, a task appears to have higher utilization
- The formula compensates: `f_next = 1.25 × f_curr × util`

On ARM (which has proper frequency scale invariance in the arch timer), the formula simplifies to:
`f_next = 1.25 × f_max × util`

The 1.25× factor is a "headroom" multiplier to prevent utilization from capping at 1.0.

### schedutil Update Path

```
Task wakeup / migration / tick
  → update_load_avg() (PELT update)
  → cpufreq_update_util() (if flags & UPDATE_FREQ)
  → sugov_update_single() / sugov_update_shared()
  → compute desired frequency
  → Rate-limit check (default: 10ms between updates)
  → cpufreq_driver_fast_switch()
  → Driver writes MSRs
```

### UTIL_EST

UTIL_EST is a feature that compensates for the fact that PELT decays during task sleep:

```
util_est = max(util_running, util_est_ewma)

util_est_ewma → EWMA (Infinite Impulse Response filter)
  filtered "running" value sampled on dequeue
```

This prevents performance degradation for periodic workloads — the frequency stays high enough that when the task wakes up, it's ready to go.

### UCLAMP

UCLAMP allows per-task min/max utilization clamps:
```c
struct sched_attr {
    sched_util_min;   // uclamp.min (0-1024)
    sched_util_max;   // uclamp.max (0-1024)
};
```

The per-task clamp is aggregated across all runnable tasks on the CPU, and the aggregated clamp constrains schedutil's frequency selection.

### Rate Limiting

schedutil rate-limits frequency updates to prevent thrashing:
```c
struct sugov_policy {
    unsigned int rate_limit_us;  // default: 10000 (10ms)
    ktime_t last_freq_update_time;
};
```

The rate limit is a balance:
- Too short: Frequency oscillates, power wasted on transitions
- Too long: Slow response to load changes, performance suffers

---

## 7. Impact on Thermal Behavior

### Without thermald

When only schedutil (or any governor) manages frequencies without thermald:

```
Load increases → schedutil sees high utilization → requests high P-state
→ CPU temperature rises → no proactive intervention
→ Temperature continues rising until:
  a) Load decreases naturally (workload finishes)
  b) CPU reaches ACPI passive trip (~85-95°C) → kernel throttles
  c) CPU reaches critical trip (~100°C) → emergency shutdown
```

### With thermald

```
Load increases → schedutil requests high P-state
→ Temperature rises → thermald detects via DTS
→ thermald engages cooling BEFORE critical temperature:
   - Writes max_perf_pct lower (e.g., 60%)
   - Sets RAPL power limit (e.g., 45W)
   - Uses PowerClamp if needed
→ System reaches equilibrium at target temperature
→ When load decreases, thermald relaxes constraints
```

### Key Temperature Points for Tiger Lake i7-11800H

| Temperature | Action |
|---|---|
| ~25-45°C | Idle range |
| ~45-70°C | Normal load under thermald |
| ~70-85°C | thermald begins active cooling |
| ~85-95°C | ACPI passive trip (forced throttling) |
| ~100°C | TCC activation (PROCHOT) — hardware emergency |
| ~105°C | TJunction maximum — system shutdown |

### References

- Linux kernel source: `kernel/sched/cpufreq_schedutil.c`, `drivers/cpufreq/intel_pstate.c`
- Intel Software Developer's Manual, Volume 3B, Chapter 14: Power Management
- Gherdovich, G. "The schedutil frequency scaling governor." LinuxDays 2018. [PDF]
- Lozi, J., et al. "The Linux scheduler: a decade of wasted cores." EuroSys '16.
