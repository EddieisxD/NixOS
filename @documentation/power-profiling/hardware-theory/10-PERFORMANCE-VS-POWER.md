# Performance vs Power: Trade-off Analysis

## Table of Contents

1. [The Power-Performance Continuum](#1-the-power-performance-continuum)
2. [Quantifying the Impact of Each Setting](#2-quantifying-the-impact-of-each-setting)
3. [Benchmarking Methodology](#3-benchmarking-methodology)
4. [Decision Matrix by Use Case](#4-decision-matrix-by-use-case)
5. [Under-Voltage and Other Advanced Topics](#5-under-voltage-and-other-advanced-topics)

---

## 1. The Power-Performance Continuum

Every power management setting exists on a spectrum between two extremes:

```
PERFORMANCE ←──────────────────────────────────────────────────→ POWER SAVE
        0%                       50%                       100%

Governors:
performance                   schedutil/ondemand          powersave

HWP EPP:
0 (perf)                    128 (default)                255 (power)

intel_pstate max_perf_pct:
100%                                                      0%

RAPL PL1:
TDP × N (unlimited)          TDP (balanced)              TDP × 0.5 (capped)

Turbo:
Enabled                      Auto                        Disabled

C-states:
C1 only                      C1-C6                        C1-C10

GPU:
P0 all cores                 P2/P8 when idle              D3cold
```

### Key Insight: Diminishing Returns

The relationship between power and performance is NOT linear:

```
Performance vs Power (typical CPU):
│
│   P
│   e  ┌───  90% performance at 50% power
│   r  │
│   f  │      95% perf at 70% power
│   o  │
│   r  │           99% perf at 90% power
│   m  │
│   a  │                    100% perf at 100% power (turbo)
│   n  │
│   c  └────────────────────────────────────
│      e
│      50%       70%       90%      100%
│            Power (fraction of max)
```

The "sweet spot" for efficiency is typically at 60-80% of maximum power — where you get 90-95% of performance.

---

## 2. Quantifying the Impact of Each Setting

### CPU Governor Impact

| Governor | Relative Performance | Relative Power | Use Case |
|---|---|---|---|
| `performance` | 100% (max freq) | 100%+ (never idles low) | Benchmarking, latency-critical |
| `schedutil` | 95-100% (adaptive) | 30-60% (adaptive) | General use |
| `ondemand` | 90-98% (sampling delay) | 35-55% | Legacy systems |
| `powersave` | 20-80% (min freq, depends on load) | 20-50% | Minimal power tasks |

**Note**: With HWP + active mode, `powersave` governor provides DYNAMIC scaling (not fixed min) and performs similarly to schedutil.

### EPP Impact (HWP only)

| EPP Setting | Performance Impact | Power Impact | Thermal Impact |
|---|---|---|---|
| `performance` (0) | +5-10% vs default | +10-20% vs default | Significantly hotter |
| `default` (128) | Baseline | Baseline | Baseline |
| `power` (255) | -5-10% vs default | -15-25% vs default | Significantly cooler |

### RAPL PL1 Impact

| PL1 Setting | Performance Impact | Power Impact | Thermal Impact |
|---|---|---|---|
| Unlimited (e.g., 107W) | Max turbo sustained | 107W package | Very hot |
| TDP (45W for i7-11800H) | Base frequency sustained | 45W package | Moderate |
| Reduced (35W) | ~20-30% drop (all-core) | 35W package | Cool |
| Minimum (15W) | ~50-70% drop (all-core) | 15W package | Very cool |

### Turbo Disable Impact

| Setting | Performance Impact | Power Impact | Thermal Impact |
|---|---|---|---|
| Turbo enabled | +30-50% (single-thread) | +20-40% peak | Hot |
| Turbo disabled | Baseline | Baseline | Moderate |

---

## 3. Benchmarking Methodology

### Recommended Tools for Testing This System

```bash
# CPU benchmarks
nix-shell -p stress sysbench

# Single-thread performance
sysbench cpu --threads=1 --time=30 run

# Multi-thread performance
sysbench cpu --threads=16 --time=30 run

# Sustained load thermal test
stress --cpu 16 --timeout 300

# GPU test
nix-shell -p cuda cuda-samples
cuda-samples/deviceQuery  # Check GPU
```

### Benchmark Protocol

```
1. Measure baseline at idle (30s):
   - CPU temperature
   - Package power (RAPL)
   - GPU power/temp
   - CPU frequency

2. Apply workload (120s):
   - Single-thread CPU
   - Multi-thread CPU
   - GPU (if applicable)

3. Record:
   - Peak temperature
   - Steady-state temperature (last 30s of workload)
   - Frequency during workload
   - Any throttling events
   - Time to reach thermal equilibrium

4. Change ONE variable, repeat
```

### What to Measure

```bash
# Temperature over time
for i in $(seq 1 20); do
  echo "$(date +%s) $(cat /sys/class/thermal/thermal_zone*/temp | tr '\n' ' ')"
  sleep 5
done > temp_log.txt

# Power over time
for i in $(seq 1 20); do
  echo "$(date +%s) $(cat /sys/devices/powercap/intel-rapl/intel-rapl:0/energy_uj)"
  sleep 5
done > power_log.txt
# Then convert to watts: diff * 15.3e-6 / interval
```

---

## 4. Decision Matrix by Use Case

| Use Case | Governor | HWP EPP | Turbo | PL1 | GPU | thermald |
|---|---|---|---|---|---|---|
| **Battery / Light work** | powersave | power (255) | Off | 25W | Removed (no-gpu) | On (target 70°C) |
| **Office / Web browsing** | schedutil | balance_power (192) | On | 35W | P8 (RTD3) | On (target 75°C) |
| **General use** | schedutil | default (128) | On | 45W | P8 (RTD3) | On (target 80°C) |
| **Gaming** | schedutil | balance_performance (64) | On | 80W | P0 active | On (target 85°C) |
| **Benchmarking** | performance | performance (0) | On | Max | P0 active | Off (manual control) |

### NixOS Implementation

For the gaming use case, a NixOS specialization or a script to toggle:

```nix
# Gaming specialization
specialisation."gaming".configuration = {
  powerManagement.cpuFreqGovernor = "performance";
  # Could also set kernelParams, systemd services, etc.
};
```

---

## 5. Under-Voltage and Other Advanced Topics

### Undervolting

Undervolting reduces CPU core voltage below stock, reducing power consumption at the same frequency. This reduces heat without affecting performance.

- **Intel**: Available via MSR (MSR_IA32_OVERCLOCKING, 0x194) on some mobile SKUs
- **Tools**: `intel-undervolt`, `throttled` (for Lenovo specific)
- **Risk**: System instability if voltage too low
- **Typical saving**: 5-15°C temperature reduction at same performance

### PowerClamp

The intel_powerclamp driver forces idle cycles to reduce temperature. It's thermald's last-resort cooling method:

```bash
echo 20 | sudo tee /sys/class/thermal/cooling_device1/cur_state
# CPU idle 20% of the time → ~20% performance loss, proportional temperature drop
```

### GPU Undervolting

NVIDIA GPUs can also be undervolted:
```bash
nvidia-smi -lgc 1200,2100  # Lock clock range
nvidia-smi -lmc 5001        # Lock memory clock
# Or use nvidia-settings for undervolting curves
```

### Important Warnings

1. **Thermal paste**: If your laptop is 2+ years old, the thermal paste may have dried out. Reapplying can reduce temperatures by 5-15°C.
2. **Dust accumulation**: Blocked vents significantly impair cooling. Clean them.
3. **Elevation**: Laptops on soft surfaces (beds, pillows) overheat quickly. Use a hard surface or stand.

### References

- Intel: [Thermal Management in Tiger Lake](https://www.intel.com/content/www/us/en/developer/articles/technical/thermal-management-in-tiger-lake.html)
- Phoronix: Various Linux power management benchmarks
- Notebookcheck: Laptop cooling reviews and thermal testing methodology
- Intel SDM, Vol. 3B: Overclocking and undervolting MSRs
