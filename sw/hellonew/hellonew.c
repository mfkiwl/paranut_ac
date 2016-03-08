#include <stdio.h>
#include <or1k-support.h>
#include <stdint.h>


static volatile int locked = 0;

void lock(){
//printf("AD:%p\n", &locked);
printf("locking\n");
int flag;
while(1){
//printf("entered_loop\n");
	asm("l.lwa\t\t%0, 0(%1)":  "=r"(flag): "r"(locked));
printf("N%i\n", flag);
	if(flag) continue;
//printf("first_cont, N%i\n"), flag;
	
	asm("l.swa\t\t0(%0), %1": : "r"(locked), "r"(1));

	flag = (or1k_mfspr(0x00000011)) & (1<<9);
	if(!flag){printf("INVALID%i ", flag); continue;}
	printf("locked\n");
	break;

}
}

void unlock(){
printf("unlocking\n");
int flag;

asm("l.lwa\t\t%0, 0(%1)":  "=r"(flag): "r"(locked));
	if(!flag) printf("error: attempting to unlock while lock is false");
//printf("%i\n", flag);
asm("l.swa\t\t0(%0), %1": : "r"(locked), "r"(0));
	flag = or1k_mfspr(0x00000011) & (1<<9);
	if(!flag) printf("error: setting lock to false did not succeed");

printf("unlocked\n");

}


int main(){

//printf("Firstline\n");

int i, j=0;
//printf("I:%p\n", &i);
/*
for(i=0; i<20; i++){
	j=j+2;
	printf("%i, %i\n", j, i);


}
*/

uint32_t SPR_ID, SPR_VAL;

SPR_ID = 0x0000C010;

lock();
printf("Readingfirst\n");
SPR_VAL = or1k_mfspr(SPR_ID);
unlock();
printf("  %ifirst\n", SPR_VAL);

lock();
printf("Readingsecond\n");
SPR_VAL = or1k_mfspr(SPR_ID);
unlock();
printf("  %isecond\n", SPR_VAL);

/*
SPR_VAL = or1k_mfspr(SPR_ID);
printf("  %ithird\n", SPR_VAL);

SPR_VAL = or1k_mfspr(SPR_ID);
printf("  %ifourth\n", SPR_VAL);
/*
SPR_VAL = or1k_mfspr(SPR_ID);
printf("  %ififth\n", SPR_VAL);


SPR_VAL = or1k_mfspr(SPR_ID);
printf("  %isixth\n", SPR_VAL);

SPR_VAL = or1k_mfspr(SPR_ID);
printf("  %iseventh\n", SPR_VAL);
*/
asm("l.nop\t0x1");

}
