#!/bin/bash

##############################################################
# setup.sh: 
# Set up two cpu and cpuset cgroups for investigation on
# CONFIG_RT_GROUP_SCHED and bandwidth allocation limit.
##############################################################

mkdir /sys/fs/cgroup/cpu,cpuacct/1 /sys/fs/cgroup/cpu,cpuacct/2
echo 500000 > /sys/fs/cgroup/cpu,cpuacct/1/cpu.rt_runtime_us
echo 500000 > /sys/fs/cgroup/cpu,cpuacct/2/cpu.rt_runtime_us

mkdir /sys/fs/cgroup/cpuset/1 /sys/fs/cgroup/cpuset/2
echo 1 > /sys/fs/cgroup/cpuset/1/cpuset.cpus
echo 2 > /sys/fs/cgroup/cpuset/2/cpuset.cpus

echo $(cat /sys/fs/cgroup/cpuset/cpuset.mems) > /sys/fs/cgroup/cpuset/1/cpuset.mems
echo $(cat /sys/fs/cgroup/cpuset/cpuset.mems) > /sys/fs/cgroup/cpuset/2/cpuset.mems