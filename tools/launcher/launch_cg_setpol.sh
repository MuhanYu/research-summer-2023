#!/bin/bash

#####################################################################
# launch.sh: 
# Driver script for launcher. Used to launch tools/setpolicy.sh and
# tools/cgroup.sh
#
# Usage: ./launch_cg_setpol.sh <trace file index #> 
#####################################################################

$launcher_source="launcher.c"
$launcher_exe="launcher"

output_directory="../../traces/load_imbalance/uclamp/launch_cg_setpol"

../nprocs/cgroup.sh $1 $output_directory
../nprocs/setpolicy.sh $1 $output_directory
