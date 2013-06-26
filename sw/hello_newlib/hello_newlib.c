#include <stdio.h>
#include <unistd.h>

#include <or1k-newlib-support.h>



int main () {
  int n;

  //or1k_icache_enable ();
  //or1k_dcache_enable ();

  for (n = 1; n <= 10; n++)
    printf ("%2i. Hello World!\n", n);
  return 0;
}
