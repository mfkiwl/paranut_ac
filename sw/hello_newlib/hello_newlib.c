#include <stdio.h>
#include <unistd.h>


int main () {
  int n;

  for (n = 1; n <= 10; n++)
    printf ("%2i. Hello World!\n", n);
  return 0;
}
