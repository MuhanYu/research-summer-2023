traces/no_check

This directory contains trace files used to explore the behavior of programs 
under regular cgroup-v1 real-time group scheduling and "no-check" group scheduling.
Processes are placed into cgroups with a real-time period and runtime, as well
as either disjoint or overlapping cpusets (with respect to other cgroups).

The trace files are collected by tools/launcher/launcher_driver.sh and a modified
version of tools/nprocs/cgroup.sh named ...

There are two subdirectories are no_check_rt_group_uclamp and rt_group_uclamp.
They refer to following kernels:

Linux muhanyupi 5.10.17-v7_no_check_rt_group_uclamp #12 SMP PREEMPT Thu Jul 6 00:52:03 CDT 2023 armv7l GNU/Linux
...


Trace file naming:


