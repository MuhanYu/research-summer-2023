#!/bin/bash

#####################################################################
# run.sh: 
# Trace processes created by nprocs, create and add them to 
# cpu and cpuset cgroups for investigating CONFIG_RT_GROUP_SCHED.
#####################################################################

temp_proc_file="procs_temp.txt"
trace_file="trace.dat"
source_file="nprocs.c"
exe_file="nprocs"
num_cpus=4 # const

sleep_time=10

rt_policy="R"

# num_procs should be a multiple of num_cgroups
# each cgroup has (num_procs/num_cgroups) processes 
num_procs=4
num_cgroups=1
num_cpus_per_cgroup=1

# cpu.rt_runtime_us interface file
rt_runtime_us=300000

# setup cgroups
for (( i=0; i<$num_cgroups; i++ ))
do
    # setup cpu cgroup
    mkdir /sys/fs/cgroup/cpu,cpuacct/$i
    echo $rt_runtime_us > /sys/fs/cgroup/cpu,cpuacct/$i/cpu.rt_runtime_us

    # setup cpuset cgroup
    mkdir /sys/fs/cgroup/cpuset/$i
    counter=0
    cpuset=""
    for (( cpu=$((num_cpus_per_cgroup*i)); cpu<$num_cpus; cpu++))
    do
        cpuset+="${cpu} "
        counter=$((counter+1))
        if [ $counter == $num_cpus_per_cgroup ]; then
            break
        fi
    done
    echo $cpuset > /sys/fs/cgroup/cpuset/$i/cpuset.cpus
    echo $(cat /sys/fs/cgroup/cpuset/cpuset.mems) > /sys/fs/cgroup/cpuset/$i/cpuset.mems
done
echo "cgroups created..."

rm -f $exe_file
gcc $source_file -o $exe_file

rm -f $trace_file
rm -f $temp_proc_file

trace_pid=0
trace-cmd record -e sched_switch \
    -o ${rt_policy}.${num_procs}p.${num_cgroups}cg.${num_cpus_per_cgroup}cpupcg.${rt_runtime_us}us.trace.dat \
    ../schedtool/schedtool -${rt_policy} -p 90 -e ./$exe_file $((num_procs-1)) &> /dev/null &
trace_pid=$!

echo "tracing started..."
sleep $sleep_time

killall -s SIGUSR1 $exe_file
echo "SIGUSR1 sent..."
sleep $sleep_time

# add to cgroup
index=0
while read -r line
do
    # add to cpuset cgroups
    # each cgroup has a single effective cpu
    echo $line > /sys/fs/cgroup/cpuset/$((index%num_cgroups))/tasks
    # add to RT cgroups
    echo $line > /sys/fs/cgroup/cpu,cpuacct/$((index%num_cgroups))/tasks
    index=$((index+1))
done < $temp_proc_file 

echo "added to cgroups..."
sleep $sleep_time

##################################################################
# Use this to verify cgroup membership
# cat cpu,cpuacct/0/tasks cpu,cpuacct/1/tasks cpuset/0/tasks cpuset/1/tasks
# cat cpu,cpuacct/0/cgroup.procs cpu,cpuacct/1/cgroup.procs cpuset/0/cgroup.procs cpuset/1/cgroup.procs
##################################################################

killall -s SIGKILL $exe_file
echo "SIGKILL sent..."

# wait for the tracing process to complete (i.e. when all
# nprocs process are terminated by SIGKILL)
# move trace file to /traces
wait $trace_pid 
echo "tracing completed..."
mv ${rt_policy}.${num_procs}p.${num_cgroups}cg.${num_cpus_per_cgroup}cpupcg.${rt_runtime_us}us.trace.dat \
    ../../traces/${rt_policy}_disjoint_cpuset_no_chk_rt_group/

# remove cgroups
for (( i=0; i<$num_cgroups; i++ ))
do
    rmdir /sys/fs/cgroup/cpu,cpuacct/$i
    rmdir /sys/fs/cgroup/cpuset/$i
done
echo "cgroups removed..."

rm -f $temp_proc_file