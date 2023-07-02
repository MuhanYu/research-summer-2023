/*
    tg_reader.c:
    Creates a kobject in the directory /sys/kernel/tg_reader with filename pid.
    Uses the kernel example kobject code at samples/kobject/kobject-example.c
*/

#include <linux/kobject.h>
#include <linux/string.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

#include <linux/pid.h>          /* For find_vpid and get_pid_task */
#include <linux/sched.h>        /* For struct task_struct */
#include <linux/sched/signal.h> /* For for_each_process */

static int pid;

static ssize_t pid_show(struct kobject *kobj, struct kobj_attribute *attr,
			            char *buf) {
    return sprintf(buf, "%d\n", pid);
}

static ssize_t pid_store(struct kobject *kobj, struct kobj_attribute *attr,
                        const char *buf, size_t count) {
    
    int ret;
    struct pid          *pidp;
    struct task_struct  *taskp;

    ret = kstrtoint(buf, 10, &pid);
    if (ret < 0) {
        return ret;
    }

    /* using find_get_pid() instead of find_vpid() because the former
       uses rcu locking and reference counting */
    pidp = find_get_pid(pid);
    if (!pidp) {
        return -EFAULT;
    }

    taskp = get_pid_task(pidp, PIDTYPE_PID);
    if (!taskp) {
        return -EFAULT;
    }

#ifdef CONFIG_CGROUP_SCHED
    printk("pid: [%d] comm: [%s] task_group: [%p]\n",
            pid, taskp->comm, taskp->sched_task_group);
#else
    printk("pid: [%d] comm: [%s]\n",
            pid, taskp->comm);
#endif

    return count;
}

static struct kobj_attribute pid_attribute =
	                __ATTR(pid, 0664, pid_show, pid_store);

static struct attribute *attrs[] = {
    &pid_attribute.attr,
    NULL,	/* need to NULL terminate the list of attributes */
};

static struct attribute_group attr_group = {
	.attrs = attrs,
};

static struct kobject *tg_reader;

static int __init tg_reader_init(void)
{
	int retval;
	tg_reader = kobject_create_and_add("tg_reader", kernel_kobj);
	if (!tg_reader)
		return -ENOMEM;

	/* Create the files associated with this kobject */
	retval = sysfs_create_group(tg_reader, &attr_group);
	if (retval)
		kobject_put(tg_reader);

	return retval;
}

static void __exit tg_reader_exit(void)
{
	kobject_put(tg_reader);
}

module_init(tg_reader_init);
module_exit(tg_reader_exit);
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Muhan Yu");