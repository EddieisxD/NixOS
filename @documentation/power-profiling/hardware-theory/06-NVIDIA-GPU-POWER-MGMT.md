# NVIDIA GPU Power Management on Linux

## Table of Contents

1. [Overview](#1-overview)
2. [NVIDIA PRIME Offload](#2-nvidia-prime-offload)
3. [PCIe Power States](#3-pcie-power-states)
4. [NVIDIA Driver Power Management Settings](#4-nvidia-driver-power-management-settings)
5. [The P-State Hierarchy](#5-the-p-state-hierarchy)
6. [Runtime D3 (RTD3)](#6-runtime-d3-rtd3)
7. [PCI Device Removal (Complete Power-Off)](#7-pci-device-removal-complete-power-off)
8. [Practical Effects on the Investigation](#8-practical-effects-on-the-investigation)

---

## 1. Overview

An NVIDIA dGPU in a laptop typically has several power states that the Linux driver can manage:

| State | Hardware State | Power Draw | Latency to On |
|---|---|---|---|
| D0-P0 | Full performance | 80-130W (load) | Instant |
| D0-P2 | Medium performance | ~30-60W | Instant |
| D0-P8 | Minimum idle (clocks gated) | 10-15W | ~100ms |
| D3hot | PCIe suspend (context preserved) | 5-8W | ~1s |
| D3cold | PCIe off (no power) | 0W (but needs reinit) | ~5-10s |
| Removed | PCI device removed | 0W | Reboot required |

The system's RTX 3070 Laptop GPU: TDP is typically 80-130W depending on OEM configuration.

---

## 2. NVIDIA PRIME Offload

The system uses NVIDIA with PRIME Offload, which means:
- The Intel iGPU (UHD Graphics / Iris Xe) drives the display
- The NVIDIA GPU is available for CUDA/rendering on demand
- Applications must be launched with `__NV_PRIME_RENDER_OFFLOAD=1` or `prime-run`

This is correctly configured:
```nix
hardware.nvidia.prime = {
  offload.enable = true;
  offload.enableOffloadCmd = true;
  intelBusId = "PCI:0@0:2:0";
  nvidiaBusId = "PCI:0@1:0:0";
};
```

Even with PRIME offload, the NVIDIA driver loads at boot and initializes the GPU. It stays in a low-power idle state (ideally P8), but our system shows P0 at idle — the highest power state.

---

## 3. PCIe Power States

The NVIDIA GPU is a PCI Express device. It can be in PCI power management states:

| PCI State | NVIDIA State | Description |
|---|---|---|
| D0 | P0-P8 | Fully operational, varying perf levels |
| D1 | (not used by NVIDIA) | Intermediate power state |
| D2 | (not used by NVIDIA) | Intermediate power state |
| D3hot | Suspended | Context maintained, PCIe clock off |
| D3cold | Off | Main power rail switched off |

Transition to D3cold requires BIOS support (ACPI _PS3 method) for the GPU's power resource.

---

## 4. NVIDIA Driver Power Management Settings

### `powerManagement.enable`

When enabled, the NVIDIA driver registers with the ACPI PCI PM subsystem. It allows the driver to transition the GPU to D3cold when no processes are using it.

- Requires system support for GPU PCIe power switching
- Checks `/proc/driver/nvidia/gpus/.../power` for "D3cold: Supported"

### `powerManagement.finegrained`

When enabled, the driver attempts more aggressive power management:
- Allows finer-grained transitions between P-states (P2, P8)
- Enables more rapid power state transitions
- Reports "Runtime D3 status: Enabled (fine-grained)" in nvidia-smi

### Our System

nvidia-smi shows:
```
Runtime D3 status:          Enabled (fine-grained)
S0ix Platform Support:     Not Supported
Video Memory:               Active
```

The good news: Runtime D3 is enabled. The bad news:
- S0ix (Modern Standby / suspend-to-idle) is not supported
- Video memory is in active state (not self-refresh)
- The GPU is in P0 performance state at 39°C with zero processes

---

## 5. The P-State Hierarchy

NVIDIA GPUs have internal performance states (note: these are different from CPU P-states):

| P-State | Engine Clock | Memory Clock | Voltage | Use Case |
|---|---|---|---|---|
| P0 | Maximum | Maximum | Maximum | 3D rendering, CUDA compute |
| P2 | Reduced | Maximum | Reduced | Video encoding, moderate GPU load |
| P8 | Minimum (~300MHz) | Minimum (~405MHz) | Minimum | Idle, no GPU processes |
| P10 | Off | Self-refresh | Minimum | Deep idle (older cards) |
| P12/15 | Off | Off | Off | (mobile, not on RTX 3070) |

### How P-States Are Selected

The NVIDIA driver selects P-states based on:
1. Whether any process has an open GPU context
2. The GPU utilization
3. Temperature readings
4. Power limit status

### Why Our GPU Is Stuck at P0

Possible reasons:
1. The `nvidia-persistenced` service keeps the GPU initialized
2. The `NVreg_EnableGpuFirmware=0` kernel option may prevent firmware-based power management
3. The GPU might not be entering D3cold due to lack of S0ix support

From nvidia-smi output:
```
Persistence-M: On
```

This means `nvidia-persistenced` is keeping the driver loaded and GPU initialized, preventing deep power state entry.

---

## 6. Runtime D3 (RTD3)

RTD3 is a mechanism where the GPU can enter PCIe D3 state when not in use, even while the laptop is running.

### How RTD3 Works

1. All GPU contexts close (no clients using GPU)
2. Driver requests PCI subsystem to transition to D3cold
3. PCI subsystem calls the GPU's ACPI _PS3 method
4. BIOS/hardware switches off GPU power rail
5. GPU is fully off (0W)

### RTD3 Requirements

- Linux kernel 5.18+ (for proper RTD3 on laptop GPUs)
- NVIDIA driver 525.60.13+ (for RTD3 support)
- GPU must be in a removable PCI slot
- BIOS must support ACPI power resources for the GPU
- nvidia-persistenced must NOT be running (it prevents RTD3)

---

## 7. PCI Device Removal (Complete Power-Off)

The `no-gpu` specialization uses udev rules to remove the NVIDIA device at PCI level:

```nix
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de",
  ATTR{class}=="0x03[0-9]*", ATTR{remove}="1"
```

When the kernel receives `ATTR{remove}="1"`, it performs:
1. PCI device state cleanup
2. Calls the driver's remove callback
3. Removes the device from the PCI bus
4. The device is now invisible to software

**Effect**: The NVIDIA GPU is completely powered off. It does not appear in `lspci`, `nvidia-smi` cannot find it, and it draws 0W.

**Downside**: The GPU is gone until next reboot. No way to re-enumerate it without a full PCI bus reset or reboot.

---

## 8. Practical Effects on the Investigation

### Impact on Overheating

The NVIDIA GPU in P0 at idle contributes:
- **Power**: ~10-15W continuous draw (estimation for P0 idle)
- **Heat**: This heat is dissipated into the shared cooling solution
- **Thermal budget**: The laptop's cooling system must handle this + CPU heat

With the `no-gpu` specialization and RTX 3070 completely removed, the cooling system has ~10-15W more thermal capacity for the CPU.

### Resolution Options

1. **Boot `no-gpu` specialization** (immediate, manual)
2. **Stop nvidia-persistenced** + enable proper RTD3:
   ```nix
   hardware.nvidia.nvidiaPersistenced = false;  # Don't keep GPU initialized
   hardware.nvidia.powerManagement.enable = true;
   hardware.nvidia.powerManagement.finegrained = true;
   ```
3. **Blacklist NVidia modules** by default, create a `with-gpu` specialization for GPU work

### References

- NVIDIA Linux driver README: [Power Management](https://us.download.nvidia.com/XFree86/Linux-x86_64/525.60.11/README/powermanagement.html)
- NVIDIA developer blog: [Dynamic Power Management](https://developer.nvidia.com/blog/dynamic-power-management-on-linux/)
- Arch Wiki: [NVIDIA Optimus / PRIME](https://wiki.archlinux.org/title/NVIDIA_Optimus)
- PCI Express Base Specification, Chapter 5: Power Management
