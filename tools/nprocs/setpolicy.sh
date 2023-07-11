#!/bin/bash

#####################################################################
# setpolicy.sh: 
# Run and trace nprocs without cgroups. Used to analyze behavior
# of real-time processes schedular inter-core load balancing as
# related to how scheduling policy is set (via schedtool/launcher,
# or the placement of sched_setscheduler() call)
#
# Usage: ./setpolicy.sh <trace file index #> <trace file subdirectory>
#####################################################################

# const variables
source_file="/home/pi/research/tools/nprocs/nprocs.c"
exe_file="/home/pi/research/tools/nprocs/nprocs"
prog_name="nprocs"

output_directory=""
if [[ $# -eq 2 ]]; then
    output_directory=$2
else
    output_directory="../../traces/load_imbalance/uclamp/high_prio_bash/"
fi

trace_time=30

rt_priority=90
rt_policy="R"

manual=0    # 0 -> use tools/schedtool/schedtool
            # 1 -> use tools/launcher/launcher
            # 2 -> call sched_setschedular() in parent before fork()
            # 3 -> call sched_setschedular() in children

num_procs=8

rm -f $exe_file

# should we compile the module for manual
# setting of scheduling policy? (via sched_setscheduler()?)
if [[ $manual -eq 0 || $manual -eq 1 ]]; then   # schedtool
    if [[ $rt_policy == "F" ]]; then
        gcc -o $exe_file -DFIFO $source_file
    else
        gcc -o $exe_file $source_file
    fi
elif [[ $manual -eq 2 ]]; then                  # parent call
    if [[ $rt_policy == "F" ]]; then
        gcc -o $exe_file -DPMANUAL -DFIFO $source_file
    else
        gcc -o $exe_file -DPMANUAL $source_file
    fi
elif [[ $manual -eq 3 ]]; then                  # child call
    if [[ $rt_policy == "F" ]]; then
        gcc -o $exe_file -DCMANUAL -DFIFO $source_file
    else
        gcc -o $exe_file -DCMANUAL $source_file
    fi
fi

trace_pid=0
if [[ $manual -eq 0 ]]; then
    trace-cmd record -e sched_switch \
    -o  setpo.${manual}m.${rt_policy}.${num_procs}p.${trace_time}s.${1}.dat \
    /home/pi/research/tools/schedtool/schedtool -${rt_policy} -p $rt_priority -e \
    ${exe_file} $((num_procs-1)) &> /dev/null &
elif [[ $manual -eq 1 ]]; then
    trace-cmd record -e sched_switch \
    -o  setpo.${manual}m.${rt_policy}.${num_procs}p.${trace_time}s.${1}.dat \
    /home/pi/research/tools/launcher/launcher 1 0 1 $rt_priority 2 \
    ${exe_file} $((num_procs-1)) -1 &> /dev/null &
else
    trace-cmd record -e sched_switch \
    -o  setpo.${manual}m.${rt_policy}.${num_procs}p.${trace_time}s.${1}.dat \
    ${exe_file} $((num_procs-1)) &> /dev/null &
fi
trace_pid=$!

echo "tracing started..."

sleep $trace_time

killall -s SIGKILL $prog_name
echo "SIGKILL sent..."

# wait for the tracing process to complete (i.e.,
# when all nprocs process are terminated by SIGKILL)
wait $trace_pid 
echo "tracing completed..."

# move trace file to the traces directory
mv setpo.${manual}m.${rt_policy}.${num_procs}p.${trace_time}s.${1}.dat ${output_directory}