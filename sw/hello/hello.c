// #include <stdio.h>
#include <support.h>

// OR32 trap vector dummy functions
void buserr_except(){}
void dpf_except(){}
void ipf_except(){}
void lpint_except(){timer_interrupt();}
void align_except(){}
void illegal_except(){}
void hpint_except(){}
void dtlbmiss_except(){}
void itlbmiss_except(){}
void range_except(){}
//void syscall_except(){}
void fpu_except(){}
void trap_except(){}
void res2_except(){}


int main () {
  int n;

  for (n = 0; n < 10; n++)
    printf ("Hello World #%i!\n", n);
}
