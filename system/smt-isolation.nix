{ config, lib, pkgs, ... }: {
  specialisation = {
    smt-isolation.configuration = {
      ############################################################
      # CONFIGURATION — CHANGE THESE IF NEEDED
      ############################################################

      # SMT pair to isolate
      # Replace with your sibling CPUs if different
      # Example: "4-5" or "2,10"
      boot.kernelParams = [
        "isolcpus=managed,6-7"
        "nohz_full=6-7"
        "rcu_nocbs=6-7"

        # housekeeping CPUs (all others)
        "housekeeping=0-5"
        "kthread_cpus=0-5"

        # timing stability
        "tsc=reliable"
        "nmi_watchdog=0"
        "audit=0"
        "mitigations=off"
      ];

      ############################################################
      # KEEP USERSPACE SERVICES OFF ISOLATED CORE
      ############################################################
      systemd.settings.Manager.DefaultCPUAffinity = "0-5";

      ############################################################
      # DISABLE AUTOMATIC IRQ BALANCING
      ############################################################
      services.irqbalance.enable = false;

      ############################################################
      # FORCE ALL IRQs AWAY FROM SMT PAIR
      ############################################################
      systemd.services.irq-affinity = {
        description = "Move all IRQs off isolated CPUs";
        wantedBy = [ "multi-user.target" ];
        after = [ "graphical.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "irq-affinity" ''
            for irq in /proc/irq/[0-9]*; do
              echo 0-5 > "$irq/smp_affinity_list" 2>/dev/null || true
            done
          '';
        };
      };

      ############################################################
      # PERF ACCESS FOR USERSPACE
      ############################################################
      boot.kernel.sysctl = {
        "kernel.perf_event_paranoid" = -1;
        "kernel.kptr_restrict" = 0;
        "kernel.perf_event_max_sample_rate" = 100000;
      };

      ############################################################
      # TOOLS YOU’LL WANT
      ############################################################
      environment.systemPackages = with pkgs; [
        linuxPackages.cpupower
        util-linux
        procps
      ];

      ############################################################
      # CONVENIENCE ALIASES
      ############################################################
      environment.shellAliases = {

        # run single thread pinned to first sibling
        smt0 = "taskset -c 6";

        # run single thread pinned to second sibling
        smt1 = "taskset -c 7";

        # run program allowed on both
        smt = "taskset -c 6,7";

        # real-time priority pinned
        smtbench = "taskset -c 6,7 chrt -f 99";

      };

    };
  };
}
