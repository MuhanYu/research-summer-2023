It seems that for the traces with 8 SCHED_RR procs, the runtime balance mechanism
is off. Some procs are getting a lot more runtime than others.

This error is due to using the schedtool program...