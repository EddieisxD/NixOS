# Linux Power Management: A Complete Hardware-Theory Reference

> **Purpose**: This directory contains a comprehensive reference on how Linux manages CPU/GPU power at every level — from the scheduler and cpufreq subsystem down to the model-specific registers (MSRs) and transistor-level operations. Every topic is connected back to the specific investigation on the Tiger Lake i7-11800H + RTX 3070 Laptop system.

## Directory Structure

```
hardware-theory/
├── README.md                          ← This file (overview + citation)
├── 01-CPU-FREQUENCY-SCALING.md        ← P-states, cpufreq subsystem, governors
├── 02-INTEL-PSTATE-DRIVER.md          ← intel_pstate active vs passive mode
├── 03-HARDWARE-PSTATES.md             ← HWP, EPP, CPPC, hardware-level details
├── 04-THERMAL-MANAGEMENT.md           ← thermald, thermal zones, trip points
├── 05-RAPL-POWER-CAPPING.md           ← Running Average Power Limit, MSRs, powercap
├── 06-NVIDIA-GPU-POWER-MGMT.md        ← NVIDIA driver PM, PCIe power states
├── 07-KERNEL-SUBSYSTEM-ARCHITECTURE.md ← Overall architecture diagram
├── 08-BIOS-UEFI-ACPI-ROLE.md          ← ACPI tables, CPPC, DSDT, _OSC
├── 09-MSRS-AND-CPU-REGISTERS.md       ← Model-specific registers reference
├── 10-PERFORMANCE-VS-POWER.md         ← Trade-off analysis, benchmarks, guidelines
├── 11-C-STATES-AND-IDLE-MANAGEMENT.md ← C-states, cpuidle, PM QoS
└── 12-SYSTEM-INTEGRATION-GUIDE.md     ← How everything connects, recommended configs
```

## Research Papers and References

PDFs are available in `../research-papers/`:

| Paper | Topic | Relevance |
|---|---|---|
| `2308.09687-graph-of-thoughts.pdf` | Graph of Thoughts: Solving Elaborate Problems with LLMs | Reasoning structure for organizing investigation |
| `2401.14295-demystifying-chains-trees-graphs.pdf` | Demystifying Chains, Trees, and Graphs of Thoughts | Taxonomy of reasoning structures for knowledge organization |
| `2502.06772-reasonflux.pdf` | ReasonFlux: Hierarchical LLM Reasoning | Hierarchical knowledge structuring |

### Key Kernel Documentation (linked)
- [cpufreq core documentation](https://docs.kernel.org/admin-guide/pm/cpufreq.html)
- [intel_pstate driver documentation](https://docs.kernel.org/admin-guide/pm/intel_pstate.html)
- [schedutil governor documentation](https://docs.kernel.org/scheduler/schedutil.html)
- [Power capping / RAPL documentation](https://docs.kernel.org/admin-guide/pm/powercap.html)

### Intel Manuals
- [Intel 64 and IA-32 Architectures Software Developer's Manual, Volume 3B: System Programming Guide, Part 2](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) — Chapters 14 (Power Management) and 15 (Thermal Management)
- Intel SDM, Volume 4: Model-Specific Registers — MSR definitions for all Intel CPU families

### Research Papers
- Gherdovich, G. (2018). "The schedutil frequency scaling governor." LinuxDays 2018. [Presentation PDF](https://www.linuxdays.cz/2018/video/Giovanni_Gherdovich-Schedutil_frequency_scaling_governor.pdf)
- Lozi, J., et al. (2016). "The Linux scheduler: a decade of wasted cores." EuroSys '16. DOI: [10.1145/2901318.2901326](https://doi.org/10.1145/2901318.2901326)
- Pallipadi, V., & Starikovskiy, A. (2006). "The ondemand governor." Proceedings of the Linux Symposium. Vol. 2.

### Online References
- [Arch Wiki: CPU Frequency Scaling](https://wiki.archlinux.org/title/CPU_frequency_scaling) — Practical configuration guide
- [Arch Wiki: Power Saving](https://wiki.archlinux.org/title/Power_saving) — Comprehensive power saving overview
- [kernel-internals.org: cpufreq and P-states](https://kernel-internals.org/power/cpufreq) — Kernel internals explanation
- [kernel-internals.org: Power Capping and RAPL](https://kernel-internals.org/power/power-capping) — RAPL internals
