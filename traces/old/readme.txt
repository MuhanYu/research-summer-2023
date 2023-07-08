traces/old: archived traces generated using tools/nprocs and the corresponding
            run_old.sh or run.sh on the "check" and "no check" rt-group 
            scheduling kernels.

Trace files naming:

<m>.{F/R}.2p.2cg.1cpupcg.500000us.trace.dat

[is safe add?].[is manual?].<RT policy>.<number of nprocs processes>.<number of cgroups>.<number of cpus per cgroup>.<cpu.rt_runtime_us>

0.  Whether procs were added to cgroups safely (i.e. by continuously adding procs 
    from a temporary PID file, stop only until the cgroup(s)'s "tasks" files have 
    the same number of PIDs as spawned). tools/nprocs/run.sh use the safe add 
    method, while run_old.sh does not.

1.  Is manual means whether the processes change their policies through 
    sched_setscheduler() ("manual"), or, the processes are launched by schedtool.
    For the "manual" option, each child process spawned by the parent calls the
    funtion individually (as opposed to having the parent call sched_setscheduler()
    and then fork children).

2.  F - SCHED_FIFO
    R - SCHED_RR

3.  The number of nprocs processes should be a multiple of the number of cgroups.

4.  Each cgroup has (num_procs/num_cgroups) processes.

5.  For the normal rt-group scheduling kernel, the sum of cpu.rt_runtime_us
    divided by cpu.rt_period_us for sibling cgroups cannot be larger than
    what is available to the parent. For the "no-check" kernel this limitation
    is removed.

Note:   For all traces in this directory, each cgroup is assigned one or two 
        cpu(s) uniquely (although they do NOT have exlusive access to the said 
        cpus, i.e. cpuset.cpu_exclusive flag is NOT set).