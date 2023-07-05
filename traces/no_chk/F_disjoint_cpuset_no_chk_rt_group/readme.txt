The traces with 8 SCHED_FIFO procs are not valid. In those two cases only four 
procs were added to the cgroup. Since the only four procs can run initially, 
only their PID were added to the temp file, read by the bash script, and 
subsequently added to the cgroup. The other four procs that didn't get to run 
initially were not added. Therefore, these stray procs hog up all four CPUs 
while the other four procs were in the cgroups, not being scheduled any runtime.