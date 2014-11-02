#ifndef PARANUT_H
#define PARANUT_H PARANUT_H

#ifdef __cplusplus
extern "C" {
#endif

int pn_get_ncpus();
int pn_get_cpuid();

void wait_for_cpu(int cpu_id);
void pn_sync_set(int cpu_id);
void pn_sync_unset(int cpu_id);
void pn_sync_clear();

#ifdef __cplusplus
}
#endif

#endif
