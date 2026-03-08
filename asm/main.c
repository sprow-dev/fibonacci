#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <stdbool.h>

extern void worker(volatile bool* stop_flag);

#define BENCH_TIME_S 5

volatile bool stop = false;

void* launch_worker(void* arg) {
    worker(&stop);
    return NULL;
}

int main() {
    printf("Benchmarking fibonacci calculation performance\n");
    printf("Test language: Assembly\n");

    pthread_t t;
    pthread_create(&t, NULL, launch_worker, NULL);

    sleep(BENCH_TIME_S);
    stop = true;
    printf("Told thread to stop.\n");

    pthread_join(t, NULL);

    FILE* f = fopen("fib.txt", "rb");
    if (!f) {
        printf("Error: fib.txt was never created. Check assembly syscalls.\n");
        return 1;
    }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fclose(f);

    double written_mb = size / (1024.0 * 1024.0);
    double mb_per_sec = written_mb / BENCH_TIME_S;

    printf("Benchmark completed in %ds.\n", BENCH_TIME_S);
    printf("Wrote %.2fMB\n", written_mb);
    printf("That's %.2f MB/s\n", mb_per_sec);

    return 0;
}
