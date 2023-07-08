traces/old/no_chk:  archived traces generated using tools/nprocs and the 
                    corresponding run_old.sh or run.sh on a 
                    5.10.17-v7_no_check_rt_group_uclamp kernel.

                    The behavior is mostly the same as with the 
                    5.10.17-v7_rt_group_uclamp kernel, except we can assign
                    >1 bandwidth ratios to two cgroups using disjoint cpusets,
                    e.g. 700000us runtime against 1000000us period for two 
                    cgroups, with the first cgroup using cpus 0-1 and the 
                    second using 2-3.


Observations:

1.  The traces with the name "OLD" in "F_disjoint_cpuset_no_chk_rt_group" are
    not valid. They have 8 procs, each with SCHED_FIFO policy. In these cases 
    only 4 procs were added to the cgroup. Since the only four procs can run 
    initially (SCHED_FIFO), only their PID were added to the temp file, read 
    by the bash script, and subsequently added to the cgroup. The other four 
    procs that didn't get to run initially were not added. Therefore, these 
    stray procs hog up all four CPUs when the other four procs were in the 
    cgroups, not being scheduled any runtime. Using the new run.sh
    eliminates this issue.

2.  Load balancing when the nprocs program is executed by schedtool or if the
    parent process calls sched_setschedular() (instead of the child processes
    calling and setting their own policy), using SCHED_RR. In a case where there 
    are 8 processes, 3 will each execute exclusively on one cpu, while the 
    remaining 5 processes will time-share the remaining cpu equally. No load 
    balancing or task migration happens over intervals as long as ~20 seconds.
    
    Calling sched_setschedular() in the child processes can eliminate this.

    It can be verified that in all cases their scheduling policy is indeed 
    SCHED_RR, despite the difference in observed scheduling behavior.

3.  For SCHED_RR, load imbalance across different cpus within a single cgroup 
    is also pretty common. For example, if 4 processes are assigned to a cgroup
    with cpuset controller set to cpus 0-1, it is common that one process hogs
    up cpu 0, while the remaining 3 processes have to share cpu 1. The scheduler
    does not seem to perform load balancing in this case.