traces/old/chk: archived traces generated using tools/nprocs and the corresponding
                run_old.sh or run.sh on a 5.10.17-v7_rt_group_uclamp kernel.

Bahavior is generally the same compared to the "no-check" kernel, except, of 
course, for this kernel, the sum of cpu.rt_runtime_us divided by 
cpu.rt_period_us for sibling cgroups cannot be larger than what is available 
to the parent. So the 700000us runtime isn't allowed or tested.