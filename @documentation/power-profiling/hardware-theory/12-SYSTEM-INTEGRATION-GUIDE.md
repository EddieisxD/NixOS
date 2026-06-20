# System Integration Guide: Putting It All Together

## Table of Contents

1. [The Overall Power Management Stack](#1-the-overall-power-management-stack)
2. [Configuration Compatibility](#2-configuration-compatibility)
3. [Recommended Configuration for This System](#3-recommended-configuration-for-this-system)
4. [Step-by-Step Fix Plan](#4-step-by-step-fix-plan)
5. [Verification Checklist](#5-verification-checklist)
6. [Monitoring and Alerting](#6-monitoring-and-alerting)

---

## 1. The Overall Power Management Stack

On the NixOS system (i7-11800H + RTX 3070), the power management stack looks like this:

```
┌──────────────────────────────────────────────────────────────┐
│  POWER MANAGEMENT STACK (CURRENT STATE)                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────┐                │
│  │  power-profiles-daemon  (power-saver)     │ ← Active      │
│  │  Can set: governor (limited), EPP (N/A)  │                │
│  └───────────────────┬──────────────────────┘                │
│                      │ via UPower D-Bus                       │
│  ┌───────────────────▼──────────────────────┐                │
│  │  Noctalia (QML desktop shell)            │ ← Active      │
│  │  Wraps PPD for UI, not a PM daemon       │                │
│  └──────────────────────────────────────────┘                │
│                                                              │
│  ┌──────────────────────────────────────────┐                │
│  │  thermald  — NOT INSTALLED               │ ← MISSING 🔴  │
│  │  Would provide: proactive thermal mgmt   │                │
│  └──────────────────────────────────────────┘                │
│                                                              │
│  ┌──────────────────────────────────────────┐                │
│  │  Kernel cpufreq: intel_cpufreq (passive) │ ← Active      │
│  │  Governor: schedutil                      │                │
│  │  No HWP, No EPP                          │ ← SUBOPTIMAL 🟡│
│  └───────────────────┬──────────────────────┘                │
│                      │                                       │
│  ┌───────────────────▼──────────────────────┐                │
│  │  Intel CPU PCU (no HWP)                  │                │
│  │  OS selects P-states via MSR_PERF_CTL    │                │
│  └───────────────────┬──────────────────────┘                │
│                      │                                       │
│  ┌───────────────────▼──────────────────────┐                │
│  │  NVIDIA RTX 3070 — P0 idle, no D3cold    │ ← SUBOPTIMAL 🟡│
│  │  nvidia-persistenced keeps GPU initialized│                │
│  └──────────────────────────────────────────┘                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### What It Should Look Like

```
┌──────────────────────────────────────────────────────────────┐
│  POWER MANAGEMENT STACK (TARGET STATE)                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────┐                │
│  │  power-profiles-daemon + thermald        │ ← Both Active ✓│
│  │  PPD: governor/EPP (needs HWP for EPP)  │                │
│  │  thermald: proactive thermal throttling  │                │
│  └───────────────────┬──────────────────────┘                │
│                      │                                       │
│  ┌───────────────────▼──────────────────────┐                │
│  │  Kernel cpufreq: intel_pstate (active)   │ ← Target ✓    │
│  │  With HWP, EPP available                 │                │
│  │  Governor: powersave (Intel HWP variant) │                │
│  └───────────────────┬──────────────────────┘                │
│                      │                                       │
│  ┌───────────────────▼──────────────────────┐                │
│  │  Intel CPU PCU (HWP active)              │                │
│  │  Hardware selects P-states from OS hints │                │
│  │  EPP: balance_power or power (EPP=128+)  │                │
│  └───────────────────┬──────────────────────┘                │
│                      │                                       │
│  ┌───────────────────▼──────────────────────┐                │
│  │  NVIDIA RTX 3070 — removed or RTD3      │ ← Target ✓     │
│  │  On battery: no-gpu specialization       │                │
│  │  On AC: P8/P2 when idle (finegrained PM) │                │
│  └──────────────────────────────────────────┘                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Configuration Compatibility

### Which Services Can Run Together?

| Service | thermald | PPD | TLP | auto-cpufreq | ananicy |
|---|---|---|---|---|---|
| **thermald** | — | ✓ Compatible | ⚠️ Overlap on RAPL | ⚠️ Overlap on governor | ✓ |
| **power-profiles-daemon** | ✓ | — | ✗ Conflict | ✗ Conflict | ✓ |
| **TLP** | ⚠️ | ✗ | — | ⚠️ | ✓ |
| **auto-cpufreq** | ⚠️ | ✗ | ⚠️ | — | ✓ |
| **ananicy** | ✓ | ✓ | ✓ | ✓ | — |

**Legend**:
- ✓ = Works together, complementary
- ⚠️ = Overlaps (one does what other does). Can run together but expect conflicts
- ✗ = Direct conflict (both try to manage the same knob)

### Detailed Conflict Analysis

**PPD + TLP**: Both try to set CPU governor, min/max frequencies, and turbo settings. They will fight each other. **Do NOT run together.**

**PPD + auto-cpufreq**: Both manage governor. auto-cpufreq additionally sets EPP and turbo. They conflict. **Do NOT run together.**

**TLP + auto-cpufreq**: Overlap on governor, frequency limits. **Not recommended.**

**thermald + anything**: thermald manages thermal throttling (RAPL limits, max_perf_pct) while the other manages governor/EPP. They operate on different control variables and can coexist. The overlap point is `max_perf_pct` where both thermald and the other service might write. thermald's writes should take priority during thermal events.

### Recommended Combinations

| Use Case | Best Combination |
|---|---|
| **Desktop / Always on AC** | thermald + (PPD or nothing) |
| **Laptop (vanilla)** | thermald + PPD |
| **Laptop (power optimized)** | thermald + TLP (with RAPL rules disabled in TLP) |
| **Minimal / Server** | thermald only |
| **Gaming optimization** | PPD (set to performance) + ananicy |

---

## 3. Recommended Configuration for This System

### Minimal Changes (Highest Impact)

1. **Enable thermald** → Most critical for overheating
2. **Fix intel_pstate mode** → Get HWP working
3. **Handle NVIDIA GPU** → Reduce baseline heat load

### modifications.nix Changes

```nix
{ pkgs, nixpkgs, lib, inputs, ... }:
{
  imports = [
    ./system/default.nix
    ./desktop-environment/default.nix
    ./virtualisation/default.nix
    ./distroagnostic_package_management.nix
    ./cachyos-tweaks.nix        # UNCOMMENT: schedutil governor, ananicy, gamemode
    ./nh.nix
    ./ldd.nix
  ];

  # ──────────────────────────────────────────────────────────────
  # Power Management — Enable for thermal control
  # ──────────────────────────────────────────────────────────────

  # Intel Thermal Daemon — PROACTIVE THERMAL MANAGEMENT
  # This is the single most important fix for overheating.
  # Without it, the CPU relies only on emergency throttle at ~95°C.
  services.thermald.enable = true;

  # power-profiles-daemon — Dynamic profile switching
  # Enabled by GNOME by default. Keep it.
  # services.power-profiles-daemon.enable = true;  # (already default with GNOME)

  # CPU Governor — explicit setting for baseline
  # schedutil is adaptive and good for most workloads
  powerManagement.cpuFreqGovernor = "schedutil";

  # upower — Battery monitoring
  services.upower.enable = true;

  # ──────────────────────────────────────────────────────────────
  # NVIDIA GPU Power Savings
  # ──────────────────────────────────────────────────────────────

  # Reduce nvidia persistenced impact
  # hardware.nvidia.nvidiaPersistenced = false;  # Becomes mkForce in no-gpu spec
}
```

### configuration.nix (Kernel) Changes

```nix
{
  # Consider LTS kernel for stability
  # boot.kernelPackages = pkgs.linuxPackages_6_12;  # or whatever is current LTS

  # Optionally force HWP active mode
  # boot.kernelParams = [ "intel_pstate=active" ];
}
```

---

## 4. Step-by-Step Fix Plan

### Phase 1: Immediate (5 minutes)

1. Enable thermald in modifications.nix:
   ```nix
   services.thermald.enable = true;
   ```
2. Rebuild: `sudo nixos-rebuild switch`
3. Verify: `systemctl status thermald`

**Expected effect**: Under load, CPU temperature will stabilize at 70-85°C instead of reaching 95°C+.

### Phase 2: Near-Term (30 minutes)

1. Investigate HWP:
   ```
   sudo dmesg | grep intel_pstate  # Check why HWP isn't active
   ```
2. Check BIOS for "Intel Speed Shift" setting
3. Try `boot.kernelParams = [ "intel_pstate=active" ];` and test
4. If HWP works, set EPP:
   ```bash
   echo power | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
   ```

**Expected effect**: Hardware-managed P-states improve efficiency by 5-15% under light load.

### Phase 3: Battery Optimization (1 hour)

1. Create a script that auto-selects `no-gpu` specialization when on battery
2. Or: Add a systemd service that enables NVIDIA RTD3 on battery, disables on AC
3. Create a power profile switching mechanism tied to AC plug/unplug events:
   ```
   udevadm monitor --property --subsystem-match=power_supply
   ```

**Expected effect**: Removing GPU power saves 5-15W on battery, reducing heat and extending battery life.

### Phase 4: Tuning (as needed)

1. Tune thermald target temperature:
   ```xml
   <TargetTemperature>75000</TargetTemperature>  <!-- 75°C target -->
   ```
2. Tune RAPL power limits via TLP or directly:
   ```bash
   echo 35000000 | sudo tee /sys/devices/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
   ```
3. Consider switching to LTS kernel if the latest kernel has regressions
4. Install and run `powertop` to identify other power consumers:
   ```bash
   sudo powertop --csv=report.csv
   ```

---

## 5. Verification Checklist

### Before (check current state)

```bash
# 1. Power services
systemctl status thermald power-profiles-daemon tlp auto-cpufreq

# 2. CPU governor and driver
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver

# 3. HWP status
cat /sys/devices/system/cpu/intel_pstate/status
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference

# 4. GPU power state
nvidia-smi

# 5. Idle temperatures
cat /sys/class/thermal/thermal_zone*/temp

# 6. Package power (0V reference)
cat /sys/devices/powercap/intel-rapl/intel-rapl:0/energy_uj
sleep 10
cat /sys/devices/powercap/intel-rapl/intel-rapl:0/energy_uj
# Calculate: difference * 15.3μJ / 10s = average power in μW
```

### After (verify fix)

```bash
# 1. thermald running
systemctl status thermald

# 2. Governor (should be schedutil or powersave)
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 3. Under load: thermald engaging
stress --cpu 4 --timeout 60 &
watch -n 1 'cat /sys/devices/system/cpu/intel_pstate/max_perf_pct'

# 4. Temperature vs before
watch -n 1 'cat /sys/class/thermal/thermal_zone*/temp | paste -sd " "'

# 5. No thermal throttling
turbostat --quiet --show PkgTmp,PkgWatt --interval 5
```

---

## 6. Monitoring and Alerting

### Real-Time Monitoring

```bash
# One-liner status dashboard
alias pm_status='echo "=== Governor ===" && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor && echo "=== Driver ===" && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver && echo "=== Freq range ===" && cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq && echo " - " && cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq && echo "=== Temps ===" && cat /sys/class/thermal/thermal_zone*/temp && echo "=== GPU ===" && nvidia-smi --query-gpu=temperature.gpu,power.draw,pstate --format=csv,noheader 2>/dev/null || echo "No GPU"'
```

### Long-Term Monitoring with Prometheus

For systematic data collection, consider:
- `nvidia_exporter` for GPU metrics
- `linux_thermal_exporter` (custom) for CPU temps
- `node_exporter` for CPU frequency + system stats

Create alerts for:
- `node_thermal_zone_temp > 85000` (CPU > 85°C sustained)
- `nvidia_gpu_temp_celsius > 80000` (GPU > 80°C)
- CPU throttling events: `rate(node_cpu_frequency_hertz{state="throttle"}[5m]) > 0`

### Stress Testing

```bash
# CPU thermal stress
stress --cpu 8 --timeout 120

# GPU thermal stress
nvidia-smi -pl 80  # Set power limit to 80W
# Run a GPU benchmark or
cuda-samples/deviceQuery

# Full system stress
stress --cpu 8 --vm 4 --hdd 2 --timeout 120 &
# While monitoring with:
watch -n 2 'echo "=== Temps ===" && cat /sys/class/thermal/thermal_zone*/temp && echo "=== CPU Freq ===" && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq && echo "=== GPU ===" && nvidia-smi --query-gpu=temperature.gpu,power.draw,pstate --format=csv,noheader'
```
