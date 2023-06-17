#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <getopt.h>
#include <signal.h>

#define NPROCS      2
#define ITERS       3000000000

#define OPT_PARENT  0
#define OPT_CHILD   1

volatile sig_atomic_t done = 0;

void sig_handler(int signum, siginfo_t *si, void *ucontext){
    done = 1;
}

void work(int option) {
    long i, unused;

    fprintf(stderr, "pid: %ld\n", (long) getpid());
    while (!done) {}
    fprintf(stderr, "Signal received!\n");

    // meaningless work
    for (i = 0; i < ITERS; i++) {
        unused = i * i * i;
    }

    if (option) exit(0);
}

int main(int argc, char *argv[]) {
    int i, status;
    pid_t pid;
    struct sigaction sa;
    sa.sa_sigaction = sig_handler;
    sa.sa_flags = SA_RESTART | SA_SIGINFO;
    sigaction(SIGUSR1, &sa, NULL);

    for (i = 0; i < NPROCS; i++) {
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
