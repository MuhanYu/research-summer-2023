#!/bin/bash

#####################################################################
# setpo.sh: 
# Run and trace nprocs without using cgroups. Used to analyze behavior
# of real-time processes schedular inter-core load balancing.
#
# Usage: ./setpo.sh <chk/no_chk> <trace file index #>
#####################################################################

# const variables
source_file="nprocs.c"
exe_file="nprocs"

output_directory="../../traces/load_imbalance/${1}/vanila"

trace_time=30

rt_policy="R"

manual=1    # 0 -> use schedtool
            # 1 -> call sched_setschedular() in parent before fork()
            # 2 -> call sched_setschedular() in children

num_procs=8

rm -f $exe_file

# should we compile the module for manual
# setting of scheduling policy? (via sched_setscheduler()?)
if [ $manual -eq 0 ]; then      # schedtool
    if [ "$rt_policy" == "F" ]; then
        gcc -o $exe_file -DFIFO $source_file
    else
        gcc -o $exe_file $source_file
    fi
elif [ $manual -eq 1 ]; then    # parent call
    if [ "$rt_policy" == "F" ]; then
        gcc -o $exe_file -DPMANUAL -DFIFO $source_file
    else
        gcc -o $exe_file -DPMANUAL $source_file
    fi
elif [ $manual -eq 2 ]; then    # child call
    if [ "$rt_policy" == "F" ]; then
        gcc -o $exe_file -DCMANUAL -DFIFO $source_file
    else
        gcc -o $exe_file -DCMANUAL $source_file
    fi
fi

trace_pid=0
if [ $manual -eq 0 ]
then
    trace-cmd record -e sched_switch \
    -o  setpo.${manual}m.${rt_policy}.${num_procs}p.${2}.dat \
    ../schedtool/schedtool -${rt_policy} -p 90 -e ./${exe_file} $((num_procs-1)) &> /dev/null &
else
    trace-cmd record -e sched_switch \
    -o  setpo.${manual}m.${rt_policy}.${num_procs}p.${2}.dat \
    ./${exe_file} $((num_procs-1)) &> /dev/null &
fi
trace_pid=$!


sleep $trace_time

# wait for the tracing process to complete (i.e.,
# when all nprocs process are terminated by SIGKILL)
wait $trace_pid 
echo "tracing completed..."

# move trace file to the traces directory
mv setpo.${manual}m.${rt_policy}.${num_procs}p.${2}.dat \
${output_directory}/set_policy_traces/


