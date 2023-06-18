#!/bin/bash

###############################################################################
# Start with a group of processes, take 2 out and assign them SCHED_RR.
# Check the task group membership of those RR tasks.
###############################################################################

rm nprocs
gcc nprocs.c -o nprocs
./nprocs 5

# Change 2 processes to SCHED_RR
# ../schedtool/schedtool -R -p 90 2550 2551

# Check the scheduling policy of all process
# ps -e -o s,pid | grep ^R | awk '{system("chrt -p " $2)}'

######
# It seems that the SCHED_RR processes still belongs to the autogroup,
# although they are now scheduled differently.
######


# ../tools/schedtool/schedtool -R -p 90 -e ./nprocs 1
