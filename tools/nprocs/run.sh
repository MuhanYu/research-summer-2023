#!/bin/bash

##############################################################
# Tracing processes, adding them to appropriate cgroups.
##############################################################

temp_proc_file="procs_temp.txt"
trace_file="trace.dat"
sleep_time=10
source_file="nprocs.c"
exe_file="nprocs"

rm $exe_file
gcc $source_file -o $exe_file

rm -f $trace_file
trace-cmd record -e sched_switch ../schedtool/schedtool -R -p 90 -e ./$exe_file 1 &> /dev/null &
echo "tracing started..."
sleep $sleep_time

killall -s SIGUSR1 $exe_file
echo "signals sent..."
sleep $sleep_time

# add to cgroup
index=1
while read -r line
do
    # add to cpuset cgroups
    # each cgroup has a single effective cpu
    echo $line > /sys/fs/cgroup/cpuset/$index/tasks
    # add to RT cgroups
    # each cgroup has runtime=500000 period=1000000
    echo $line > /sys/fs/cgroup/cpu,cpuacct/$index/tasks
    index=$((index+1))
done < $temp_proc_file 

echo "added to cgroups..."
sleep $sleep_time

####
# Use this to verify cgroup membership
# cat cpu,cpuacct/1/tasks cpu,cpuacct/2/tasks cpuset/1/tasks cpuset cpuset/2/tasks
# cat cpu,cpuacct/1/cgroup.procs cpu,cpuacct/2/cgroup.procs cpuset/1/cgroup.procs cpuset cpuset/2/cgroup.procs
####

killall -s SIGKILL $exe_file
echo "all processes terminated..."
rm -f $temp_proc_file