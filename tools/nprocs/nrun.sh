#!/bin/bash

#####################################################################
# nrun.sh: 
# Slightly modified version of run.sh for SCHED_FIFO
#####################################################################

temp_proc_file="procs_temp.txt"
trace_file="trace.dat"
source_file="nprocs.c"
exe_file="nprocs"
num_cpus=4 # const

sleep_time=10

manual=0

rt_policy="R"

# num_procs should be a multiple of num_cgroups
# each cgroup has (num_procs/num_cgroups) processes 
num_procs=8
num_cgroups=2
num_cpus_per_cgroup=2

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

# should we compile the module for manual
# setting of sched policy? (via sched_setscheduler()?)
if [ $manual -eq 1 ]
then
    if [ "$rt_policy" == "F" ]
    then
        gcc -o $exe_file -DCMANUAL -DFIFO $source_file
    else
        gcc -o $exe_file -DCMANUAL $source_file
    fi
else
    if [ "$rt_policy" == "F" ]
    then
        gcc -o $exe_file -DFIFO $source_file
    else
        gcc -o $exe_file $source_file
    fi
fi

rm -f $trace_file
rm -f $temp_proc_file

trace_pid=0
if [ $manual -eq 1 ]
then
    trace-cmd record -e sched_switch \
    -o  safeadd.m.${rt_policy}.${num_procs}p.${num_cgroups}cg.${num_cpus_per_cgroup}cpupcg.${rt_runtime_us}us.trace.dat \
    ./nprocs $((num_procs-1)) &> /dev/null &
else
    trace-cmd record -e sched_switch \
    -o safeadd.${rt_policy}.${num_procs}p.${num_cgroups}cg.${num_cpus_per_cgroup}cpupcg.${rt_runtime_us}us.trace.dat \
    ../schedtool/schedtool -${rt_policy} -p 90 -e ./$exe_file $((num_procs-1)) &> /dev/null &
fi
trace_pid=$!

echo "tracing started..."
sleep $sleep_time

killall -s SIGUSR1 $exe_file
echo "SIGUSR1 sent..."
sleep $sleep_time

# add to cgroup
index=0
while [ $index -lt $num_procs ]
do
    while read -r line
    do
        # calculate current index based on the total number of procs
        # already in cgroups. Duplicate PIDS are not an issue because
        # they are only generated when the process got moved to another 
        # cgroup and then back or the PID got recycled while reading
        index=0
        for (( i=0; i<$num_cgroups; i++))
        do
            temp=$(wc -l < /sys/fs/cgroup/cpuset/$((i))/tasks)
            index=$((index+temp))
        done
        if [ $index -eq $num_procs ]
        then
            break
        fi
        # add to cpuset cgroups
        # each cgroup has a single effective cpu
        echo $line > /sys/fs/cgroup/cpuset/$((index%num_cgroups))/tasks
        # add to RT cgroups
        echo $line > /sys/fs/cgroup/cpu,cpuacct/$((index%num_cgroups))/tasks
    done < $temp_proc_file 
done

echo "added to cgroups..."
sleep $sleep_time

killall -s SIGKILL $exe_file
echo "SIGKILL sent..."

# wait for the tracing process to complete (i.e. when all
# nprocs process are terminated by SIGKILL)
# move trace file to /traces
wait $trace_pid 
echo "tracing completed..."

if [ $manual -eq 1 ]
then
    mv safeadd.m.${rt_policy}.${num_procs}p.${num_cgroups}cg.${num_cpus_per_cgroup}cpupcg.${rt_runtime_us}us.trace.dat \
    ../../traces/${rt_policy}_disjoint_cpuset_no_chk_rt_group/
else
    mv safeadd.${rt_policy}.${num_procs}p.${num_cgroups}cg.${num_cpus_per_cgroup}cpupcg.${rt_runtime_us}us.trace.dat \
    ../../traces/${rt_policy}_disjoint_cpuset_no_chk_rt_group/
fi

# remove cgroups
for (( i=0; i<$num_cgroups; i++ ))
do
    rmdir /sys/fs/cgroup/cpu,cpuacct/$i
    rmdir /sys/fs/cgroup/cpuset/$i
done
echo "cgroups removed..."

rm -f $temp_proc_file