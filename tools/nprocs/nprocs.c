#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <getopt.h>
#include <signal.h>

#define ITERS               2000000
#define TEMP_PROCS_FILE     "procs_temp.txt"
#define MAX_BUF             10

#define OPT_PARENT  0
#define OPT_CHILD   1

volatile sig_atomic_t done = 0;

void sig_handler(int signum, siginfo_t *si, void *ucontext){
    done = 1;
}

void work(int option) {
    long i, j, unused;
    pid_t pid;
    FILE *fp;

    fp = fopen(TEMP_PROCS_FILE, "a");
    if (fp == NULL) {
        perror("fopen()");
        exit(-1);
    }

    pid = getpid();

    fprintf(fp, "%ld\n", (long) pid);
    fclose(fp);
    printf("pid: %ld\n", (long) pid);

    while (!done) {}
    printf("Signal received!\n");

    // meaningless work
    for (i = 0; i < ITERS; i++) {
        for (j = 0; j < ITERS; j++) {
            unused = j * j * j;
        }
    }

    if (option) exit(0);
}

int main(int argc, char *argv[]) {
    int i, status, nchildren;
    pid_t pid;
    char str[MAX_BUF];
    struct sigaction sa;

    sa.sa_sigaction = sig_handler;
    sa.sa_flags = SA_RESTART | SA_SIGINFO;
    sigaction(SIGUSR1, &sa, NULL);

    nchildren = atoi(argv[1]);

    for (i = 0; i < nchildren; i++) {
        pid = fork();
        if (pid == 0) {
            work(OPT_CHILD);
            break;
        }
        else if (pid == -1) {
            perror("fork()");
            return -1;
        }
    }

    work(OPT_PARENT);

    // wait for all children
    while ((pid = wait(&status)) != -1) {}

    return 0;
}
