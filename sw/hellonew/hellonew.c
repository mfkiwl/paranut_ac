#include <stdio.h>
#include <or1k-support.h>
#include <stdint.h>






int main(){
int i;

uint32_t SPR_ID, SPR_VAL;

SPR_ID = ((0b11000 <<11)| 0x0);
SPR_VAL = or1k_mfspr(SPR_ID);


printf("%i \n", SPR_VAL);

for(i=0; i<5; i++){
	printf("test \n");
}


}

asm("l.nop\t0x1");
