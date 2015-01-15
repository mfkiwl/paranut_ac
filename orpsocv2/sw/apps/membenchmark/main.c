/*
 * Simple memory benchmark
 *
 * (C) 2011 Stefan Kristiansson
 * GPLv2 or later
 */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <or1k-support.h>
#include <spr-defs.h>

#define MEM_SIZE 0x40000
#define MEM_SIZE_B (MEM_SIZE*4)
#define MEM_SIZE_KB ((MEM_SIZE_B)/1024)
#define MEM_SIZE_MB (MEM_SIZE_KB/1024)
#if 0
#define MEMBENCH_DEBUG
#endif
extern unsigned long _board_clk_freq;
#define clk_freq _board_clk_freq

#include "counter.h"
#define CTR_BA 0xf0000000

static unsigned mem[MEM_SIZE];
static unsigned rand_table[MEM_SIZE];

static inline void timer_enable()
{
	//or1k_mtspr(SPR_TTMR, SPR_TTMR_CR);
    counter_init(clk_freq);
	counter_start(CTR_BA, 0);
}

static inline void timer_disable()
{
	//or1k_mtspr(SPR_TTMR, 0);
	counter_stop(CTR_BA, 0);
}

static inline void timer_reset_ticks()
{
	//or1k_mtspr(SPR_TTCR, 0);
	counter_reset(CTR_BA, 0);
}

static inline unsigned timer_get_ticks()
{
	//return or1k_mfspr(SPR_TTCR);
	return counter_get_cnt(CTR_BA, 0);
}

static void precalc_rand()
{
	int i;

	for (i = 0; i < MEM_SIZE; i++)
		rand_table[i] = ((unsigned)rand())%MEM_SIZE;
}
static inline unsigned get_rand(int index)
{
	return rand_table[index];
}
/* 
 * NOTE: wrapping of timer is not taken account for anywhere
 * keep the mem size small enough so the test passes within the timers
 * range
 */

unsigned benchmem_linear_read(unsigned *memarea, int memsize)
{
	int i;
	volatile unsigned tmp;

	timer_reset_ticks();
	for (i = 0; i < memsize; i++)
		tmp = memarea[i];		
	return timer_get_ticks();
}

unsigned benchmem_random_read(unsigned *memarea, int memsize)
{
	int i;
	volatile unsigned tmp;

	timer_reset_ticks();
	for (i = 0; i < memsize; i++)
		tmp = memarea[get_rand(i)];		
	/* divide by two to account for the random table access */
	return timer_get_ticks()/2;
}

unsigned benchmem_linear_write(unsigned *memarea, int memsize)
{
	int i;
	volatile unsigned tmp = 0;

	timer_reset_ticks();
	for (i = 0; i < memsize; i++)
		memarea[i] = tmp;		
	return timer_get_ticks();
}

unsigned benchmem_random_write(unsigned *memarea, int memsize)
{
	int i;
	volatile unsigned tmp = 0;

	timer_reset_ticks();
	for (i = 0; i < memsize; i++)
		memarea[get_rand(i)] = tmp;		
	/* divide by two to account for the random table access */
	return timer_get_ticks()/2;
}

unsigned benchmem_linear_read_write(unsigned *memarea, int memsize)
{
	int i;
	volatile unsigned tmp = 0;

	timer_reset_ticks();
	for (i = 0; i < memsize; i++) {
		tmp = memarea[i];		
		memarea[i] = tmp;
	}
	return timer_get_ticks();
}

unsigned benchmem_random_read_write(unsigned *memarea, int memsize)
{
	int i;
	volatile unsigned tmp = 0;

	timer_reset_ticks();
	for (i = 0; i < memsize; i++) {
		tmp = memarea[get_rand(i)];		
		memarea[get_rand(i)] = tmp;
	}
	/* divide by two to account for the random table access */
	return timer_get_ticks()/2;
}
/* returns transfer rate in KiB/s */
unsigned calc_transfer_rate(unsigned ticks)
{
	float rate = (MEM_SIZE_B/((float)ticks/clk_freq));
#ifdef MEMBENCH_DEBUG
	printf("(ticks = %u, MEM_SIZE_B = %u, CLK_FREQ = %lu) ", 
	       ticks, MEM_SIZE_B, clk_freq);
#endif
	return ((unsigned)(rate/1024));
}

void run_tests()
{
	unsigned ticks;

	printf("Linear %d MB read... ", MEM_SIZE_MB);
	ticks = benchmem_linear_read(mem, MEM_SIZE);
	printf("%d KiB/s\r\n", calc_transfer_rate(ticks));

	printf("Linear %d MB write... ", MEM_SIZE_MB);
	ticks = benchmem_linear_write(mem, MEM_SIZE);
	printf("%d KiB/s\r\n", calc_transfer_rate(ticks));

	printf("Random %d MB read... ", MEM_SIZE_MB);
	ticks = benchmem_random_read(mem, MEM_SIZE);
	printf("%d KiB/s\r\n", calc_transfer_rate(ticks));

	printf("Random %d MB write... ", MEM_SIZE_MB);
	ticks = benchmem_random_write(mem, MEM_SIZE);
	printf("%d KiB/s\r\n", calc_transfer_rate(ticks));

	printf("Linear %d MB read and write... ", MEM_SIZE_MB);
	ticks = benchmem_linear_read_write(mem, MEM_SIZE);
	printf("%d KiB/s\r\n", calc_transfer_rate(ticks));

	printf("Random %d MB read and write... ", MEM_SIZE_MB);
	ticks = benchmem_random_read_write(mem, MEM_SIZE);
	printf("%d KiB/s\r\n", calc_transfer_rate(ticks));
}

int main()
{
	timer_enable();
	timer_reset_ticks();

	printf("\r\nMemory benchmark test\r\n");
	printf("CPU Clock freq: %lu MHz\r\n", clk_freq/1000000uL); 
	printf("Precalculating random table\r\n");
	precalc_rand();
	or1k_icache_enable();
	or1k_dcache_enable();
	printf("I-cache and D-cache enabled\r\n");
	run_tests();
	or1k_dcache_disable();
	printf("D-cache disabled\r\n");
	run_tests();
	or1k_icache_disable();
	printf("I-cache and D-cache disabled\r\n");
	run_tests();
	printf("\r\ndone!\r\n");

	for(;;);

	return 0;
}
