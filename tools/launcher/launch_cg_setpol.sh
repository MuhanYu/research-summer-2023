#!/bin/bash

#####################################################################
# launch.sh: 
# Driver script for launcher. Executes tools/setpolicy.sh and
# tools/cgroup.sh
#
# Usage: ./launch_cg_setpol.sh <trace file index #> 
#####################################################################

# priority of sudo bash, NOT priotiy of nprocs launched by setpolicy.sh
rt_priority=91 

output_directory="/home/pi/research/traces/load_imbalance/uclamp/launch_cg_setpo/"

./launcher 1 0 1 $rt_priority 5 sudo bash /home/pi/research/tools/nprocs/setpolicy.sh $1 $output_directory -1 &> /dev/null
