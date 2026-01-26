{ config, lib, pkgs, ... }:

{
  ############################################################
  # 1. KERNEL ISOLATION (RESEARCH-GRADE, MODERN)
  ############################################################
  boot.kernelParams = [
    # isolate CPU 6 completely
    "isolcpus=managed,6"
    "nohz_full=6"
    "rcu_nocbs=6"

    # keep all kernel housekeeping off CPU 6
    "housekeeping=0-5,7"
    "kthread_cpus=0-5,7"

    # timing sanity
    "tsc=reliable"
    "nmi_watchdog=0"
    "audit=0"
    "mitigations=off"
  ];

  ############################################################
  # 2. SYSTEMD: KEEP USER SERVICES OFF CPU 6
  ############################################################
  systemd.settings.Manager = {
    DefaultCPUAffinity = "0-5 7";
  };

  ############################################################
  # 3. IRQ ISOLATION (NO ASYNC NOISE)
  ############################################################
  services.irqbalance.enable = false;

  systemd.services.irq-affinity = {
    description = "Pin all IRQs away from isolated CPU 6";
    wantedBy = [ "multi-user.target" ];
    after = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "irq-affinity" ''
        for irq in /proc/irq/[0-9]*; do
          echo 0-5,7 > "$irq/smp_affinity_list" 2>/dev/null || true
        done
      '';
    };
  };

  ############################################################
  # 4. PERF / PMU ACCESS (USERSPACE)
  ############################################################
  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = -1;
    "kernel.perf_event_max_sample_rate" = 100000;
    "kernel.kptr_restrict" = 0;
  };

  ############################################################
  # 5. TOOLS (NO BOOT-TIME POLICY)
  ############################################################
  environment.systemPackages = with pkgs; [
    linuxPackages.cpupower
  ];

  ############################################################
  # 6. BENCHMARK EXECUTION CONTRACT
  ############################################################
  environment.shellAliases = {
    benchrun = "taskset -c 6 chrt -f 99";
  };
}

