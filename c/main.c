#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gmp.h>
#include <pthread.h>
#include <stdbool.h>
#include <unistd.h>

#define CACHE_SIZE (1024 * 1024)
#define BENCH_TIME_S 5

volatile bool stop = false;

void* Worker(void* arg) {
    const char* path = (const char*)arg;

    // w = write b = as bytes
    FILE* f = fopen(path,"wb");

    // ram alloc
    char* buf = malloc(CACHE_SIZE);
    setvbuf(f,buf,_IOFBF,CACHE_SIZE);

    // using c mpz modules
    mpz_t a,b,next;
    mpz_init_set_ui(a,0);
    mpz_init_set_ui(b,1);
    mpz_init(next);

    while (!stop) {
        // fib math
        mpz_add(next,a,b);
        mpz_set(a, b);
        mpz_set(b, next);

        // find the amount of limbs
        size_t size = mpz_size(b);
        const void* data = mpz_limbs_read(b);

        // writing data
        fwrite(data,sizeof(mp_limb_t),size,f);
        fputc(',',f);
    }

    // finish write ops
    fflush(f);
    // then close
    fclose(f);

    // clear mem by unreserving buf
    free(buf);
    // clean bigint vals
    mpz_clears(a,b,next,NULL);
    return NULL;
}

int main() {
    pthread_t worker_t;
    printf("Benchmarking fibonacci calculation performance\n");
    printf("Test language: C\n");
    if (pthread_create(&worker_t,NULL,Worker,"fib.txt") != 0) {
        return 1;
    }

    sleep(BENCH_TIME_S);
    stop = true;
    pthread_join(worker_t,NULL);

    // open file handle
    FILE* f = fopen("fib.txt","rb");
    // go to start
    fseek(f,0,SEEK_END);
    // get file size
    long size = ftell(f);
    // close handle
    fclose(f);

    double written_mb = size / (1024.0*1024.0);
    double mb_per_sec = written_mb / BENCH_TIME_S;

    printf("Benchmark completed in %ds.\n",BENCH_TIME_S);
    printf("Wrote %.2fMB\n",written_mb);
    printf("That's %.2f MB/s\n",mb_per_sec);

    return 0;
}
