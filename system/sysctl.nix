{ lib, ... }:

{
  boot.kernel.sysctl = {

    ##### perf / profiling #####
    "kernel.perf_event_paranoid" = -1;
    "kernel.perf_event_max_sample_rate" = 100000;

    ##### visibility / introspection #####
    "kernel.kptr_restrict" = 0;
    "kernel.dmesg_restrict" = 0;
    "kernel.yama.ptrace_scope" = 0;

    ##### scheduler / behavior #####
    "kernel.sched_autogroup_enabled" = 0;
    "kernel.sched_migration_cost_ns" = 500000;
    "kernel.timer_migration" = 0;

    ##### virtual memory #####
    "vm.swappiness" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 20;
    "vm.max_map_count" = 1048576;

    ##### limits #####
    "fs.inotify.max_user_watches" = 1048576;
    "fs.file-max" = 2097152;
    "kernel.pid_max" = 131072;

    ##### optional / advanced #####
    # "vm.zone_reclaim_mode" = 0;
    # "vm.overcommit_memory" = 1;
    # "vm.overcommit_ratio" = 100;
    # "kernel.rcu_expedited" = 1;
  };
}

