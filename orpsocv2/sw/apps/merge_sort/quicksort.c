#include <stdio.h>
#include <stdlib.h>

#include "paranut.h"
#include "paranut_hist.h"
#include "counter.h"

#define CTR_BA 0xf0000000
#define BUS_FREQ_HZ 25000000

// SIZE must be a power of two!
#define SIZE 0x80000
#define MAX_NUMBER 0xffffffff

int a[SIZE];
int tmp[SIZE];
int sorted;
unsigned int start_time, stop_time;

int compare (const void * a, const void * b)
{
  return ( *(int*)a - *(int*)b );
}

int do_check_sorted (int n0, int n1)
{
    unsigned i;
    int sorted = 1;

    for (i = 1+n0; i < n1 - n0; i++) {
        if (a[i-1] > a[i])
            sorted = 0;
    }
    return sorted;
}

int main(void)
{
    int i;
    int n_cpus = pn_get_ncpus();
    int cpu_id = pn_get_cpuid();

    if (cpu_id == 0) {
        counter_init(BUS_FREQ_HZ);
        sorted = 1;
        printf("\nGenerating random array of size %d...\n", SIZE);
        for (i = 0; i < SIZE; i++) {
            a[i] = rand() % MAX_NUMBER;
            if (i > 1 && a[i-1] > a[i])
                sorted = 0;
        }
        if (sorted)
            printf("Random array generation failed.\n");
        else
            printf("Random array generated.\n");
        printf("Running quicksort with %d CPU(s)...\n", n_cpus);
        counter_reset(CTR_BA, 0);
        counter_start(CTR_BA, 0);
        counter_set_cnt_div(CTR_BA, 0, 2);
        start_time = counter_get_msecs(CTR_BA, 0);
        pn_sync_set(0);
    }
    // Wait for random array to be generated by CPU 0...
    wait_for_cpu(0);
    if (cpu_id == 0) {
        pn_sync_unset(0);
    }
    //pn_hist_enable();

    // Begin sorting...
    qsort((void*)&a[cpu_id*SIZE/n_cpus], SIZE/n_cpus, sizeof(int), compare);

    if (cpu_id < n_cpus-1) {
        // All CPUs wait for CPUID+1. The last CPU may slip through and set its
        // signal first. Note: A strict order has to be enforced to ensure that
        // only one CPU at a time writes to the sync variable. This avoids race
        // conditions.
        wait_for_cpu(cpu_id+1);
    }

    //pn_hist_disable();

    if (cpu_id == 0) {
        stop_time = counter_get_msecs(CTR_BA, 0);
        printf("Finished sorting...");
        // Check if array is actually sorted.
        for (i = 0; i < n_cpus; i++) {
            sorted += do_check_sorted(i*SIZE/n_cpus, ((i+1)*SIZE/n_cpus)-1);
        }
        if (sorted == n_cpus) printf(" Correct operation verified.\n");
        else printf(" Correct operation could not be verified.\n");
        printf("Time elapsed: %d ms\n", stop_time - start_time);
        pn_sync_set(0);
    } else {
        pn_sync_set(cpu_id);
        wait_for_cpu(0);
    }

    return sorted-1;
}
