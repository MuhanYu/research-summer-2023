#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <getopt.h>

#define CGROUP_BASE_PATH    "/sys/fs/cgroup/"
#define MAX_PATH_LEN        256
#define MAX_LINE_LEN        80
#define NUM_THREADS         3
#define ITERS               1000000000

#define OPT_PROCESS           0
#define OPT_THREAD            1

static int change_type(const char *path) {
    char filename[MAX_PATH_LEN];
    FILE *fp = NULL; 

    snprintf(filename, MAX_PATH_LEN, "%s/cgroup.type", path);

    fp = fopen(filename, "a");
    if (fp == NULL) {
        perror("fopen()");
        return -1;
    }
    
    fprintf(fp, "threaded");

    if (fclose(fp) != 0) {
        perror("fclose()");
        return -1;
    }
}

static int join_cgroup(const char *path, int option) {
    char buf[MAX_LINE_LEN];
    char filename[MAX_PATH_LEN];
    FILE *fp = NULL; 

    if (option == OPT_THREAD)
        snprintf(filename, MAX_PATH_LEN, "%s/cgroup.threads", path);
    else
        snprintf(filename, MAX_PATH_LEN, "%s/cgroup.procs", path);

    fp = fopen(filename, "a");
    if (fp == NULL) {
        perror("fopen()");
        return -1;
    }

    if (option == OPT_THREAD)
        snprintf(buf, MAX_LINE_LEN, "%ld", (long) gettid());
    else
        snprintf(buf, MAX_LINE_LEN, "%ld", (long) getpid());
    
    fprintf(fp, "%s\n", buf);

    if (fclose(fp) != 0) {
        perror("fclose()");
        return -1;
    }

    return 0;
}


static void *thread_fn(void *arg) {
    const char *path;
    char buf[MAX_LINE_LEN];
    char filename[MAX_PATH_LEN];
    int result, i;
    FILE *fp;

    path = (const char *) arg;

    // change subtree to threaded
    snprintf(filename, MAX_PATH_LEN, "%s/cgroup.type", path);
    fp = fopen(filename, "a");
    if (fp == NULL) {
        perror("fopen()");
    }

    fprintf(fp, "threaded");
    if (fclose(fp) != 0) {
        perror("fclose()");
    }

    // add to subdir*/cgroup.threads
    join_cgroup(path, OPT_THREAD);

    for (i = 0; i < ITERS; i++) {
        result = i*i*i; // cubing
    }

    while (1);

    pthread_exit(NULL);
}

int main(int argc, char *argv[]) {
    struct stat st;
    int     opt, i, unused;
    char    cgroup_path[MAX_PATH_LEN];
    char    dir_paths[NUM_THREADS][MAX_PATH_LEN];
    pthread_t threads[NUM_THREADS];
    char    *cgroup_name = NULL;

    while((opt = getopt(argc, argv, "n:")) != -1)  
    {  
        switch(opt)  
        {  
            case 'n':  
                cgroup_name = optarg;  
                break;  
            case '?':  
                fprintf(stderr, "Unknown option: %c\n", optopt);
                return -1;
        }  
    }  

    if (cgroup_name == NULL) {
        fprintf(stderr, 
                "Usage: %s -n <cgroup_name>\n", argv[0]);
        return -1;
    }

    snprintf(cgroup_path, MAX_PATH_LEN, "%s%s", CGROUP_BASE_PATH, cgroup_name);

    for (i = 0; i < NUM_THREADS; i++) {
        snprintf(dir_paths[i], MAX_PATH_LEN, "%s/subdir%d", cgroup_path, i+1);
        if (stat(dir_paths[i], &st) == -1) {
            // subdir does not exist, no need to remove
            continue;
        }
        if (rmdir(dir_paths[i]) == -1) {
            fprintf(stderr, 
                    "Failed to remove a pre-existing subdirectory, error: %s\n", 
                    strerror(errno));
            return -1;
        }
    }

    // make a clean cgroup
    if (mkdir(cgroup_path, S_IRWXU) == -1) {
        if (errno == EEXIST) {
            if (rmdir(cgroup_path) == -1) {
                fprintf(stderr, 
                        "Failed to remove an existing cgroup directory, error: %s\n", 
                        strerror(errno));
                return -1;
            }
            if (mkdir(cgroup_path, S_IRWXU) == -1) {
                fprintf(stderr, 
                        "Failed to create a clean cgroup directory, error: %s\n", 
                        strerror(errno));
                return -1;
            }
        }
        else {
            fprintf(stderr, 
                    "Failed to create a clean cgroup directory, error: %s\n", 
                    strerror(errno));
            return -1;
        }
    }

    // add current process to cgroup
    if (join_cgroup(cgroup_path, OPT_PROCESS) == -1) {
        fprintf(stderr, "Failed to add main process to cgroup\n");
        return -1;
    }

    for (i = 0; i < NUM_THREADS; i++) {
        if (mkdir(dir_paths[i], S_IRWXU) == -1) {
            perror("Failed to create a subdirectory");
            return -1;
        }
    }

    // enable threaded cpu controller
    

    for (i = 0; i < NUM_THREADS; i++) {
        if (pthread_create(&threads[i], NULL, thread_fn, (void *) dir_paths[i])) {
            perror("pthread_create");
            return -1;
        }
    }

    for (i = 0; i < NUM_THREADS; i++) {
        if (pthread_join(threads[i], NULL)) {
            perror("pthread_join");
            return -1;
        }
    }

    return 0;
}