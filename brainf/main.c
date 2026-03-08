#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/stat.h>

extern void brainf_logic(volatile char *stop, FILE *f);
volatile char stop_bench = 0;

void* timer_thread(void* arg) {
    sleep(5);
    stop_bench = 1;
    return NULL;
}

int main() {
    printf("Benchmarking Super-Optimized Fibonacci\n");

    FILE *f = fopen("fib.txt", "wb");
    setvbuf(f, NULL, _IOFBF, 1024 * 1024);

    pthread_t thread;
    pthread_create(&thread, NULL, timer_thread, NULL);

    brainf_logic(&stop_bench, f);

    pthread_join(thread, NULL);
    fclose(f);

    struct stat st;
    if (stat("fib.txt", &st) == 0) {
        double mb = (double)st.st_size / (1024 * 1024);
        printf("Test completed. Wrote %.4f MB (%.4f MB/s)\n", mb, mb / 5.0);
    }
    return 0;
}
