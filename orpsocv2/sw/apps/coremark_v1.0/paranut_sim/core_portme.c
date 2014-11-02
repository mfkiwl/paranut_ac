/* 
	File: core_portme.c
*/
/*
	Author : Shay Gal-On, EEMBC
	Legal : TODO!
*/ 
#include <stdio.h>
#include <stdlib.h>
#include "coremark.h"
#if CALLGRIND_RUN
#include <valgrind/callgrind.h>
#endif

//#include <paranut_hist.h>
#include <paranut.h>

#if (MEM_METHOD==MEM_MALLOC)
#include <malloc.h>
/* Function: portable_malloc
	Provide malloc() functionality in a platform specific way.
*/
void *portable_malloc(size_t size) {
	void * p = malloc(size);
    if (p == NULL) {
        ee_printf("Error allocating memory\n");
        exit(1);
    }
    return p;
}
/* Function: portable_free
	Provide free() functionality in a platform specific way.
*/
void portable_free(void *p) {
	free(p);
}
#else
void *portable_malloc(size_t size) {
	return NULL;
}
void portable_free(void *p) {
	p=NULL;
}
#endif

#if (SEED_METHOD==SEED_VOLATILE)
#if VALIDATION_RUN
	volatile ee_s32 seed1_volatile=0x3415;
	volatile ee_s32 seed2_volatile=0x3415;
	volatile ee_s32 seed3_volatile=0x66;
#endif
#if PERFORMANCE_RUN
	volatile ee_s32 seed1_volatile=0x0;
	volatile ee_s32 seed2_volatile=0x0;
	volatile ee_s32 seed3_volatile=0x66;
#endif
#if PROFILE_RUN
	volatile ee_s32 seed1_volatile=0x8;
	volatile ee_s32 seed2_volatile=0x8;
	volatile ee_s32 seed3_volatile=0x8;
#endif
	volatile ee_s32 seed4_volatile=ITERATIONS;
	volatile ee_s32 seed5_volatile=0;
#endif
/* Porting: Timing functions
	How to capture time and convert to seconds must be ported to whatever is supported by the platform.
	e.g. Read value from on board RTC, read value from cpu clock cycles performance counter etc. 
	Sample implementation for standard time.h and windows.h definitions included.
*/
/* Define: TIMER_RES_DIVIDER
	Divider to trade off timer resolution and total time that can be measured.

	Use lower values to increase resolution, but make sure that overflow does not occur.
	If there are issues with the return value overflowing, increase this value.
	*/
#if USE_CLOCK
	#define NSECS_PER_SEC CLOCKS_PER_SEC
	#define EE_TIMER_TICKER_RATE 1000
	#define CORETIMETYPE clock_t 
	#define GETMYTIME(_t) (*_t=clock())
	#define MYTIMEDIFF(fin,ini) ((fin)-(ini))
	#define TIMER_RES_DIVIDER 1
	#define SAMPLE_TIME_IMPLEMENTATION 1
#elif defined(_MSC_VER)
	#define NSECS_PER_SEC 10000000
	#define EE_TIMER_TICKER_RATE 1000
	#define CORETIMETYPE FILETIME
	#define GETMYTIME(_t) GetSystemTimeAsFileTime(_t)
	#define MYTIMEDIFF(fin,ini) (((*(__int64*)&fin)-(*(__int64*)&ini))/TIMER_RES_DIVIDER)
	/* setting to millisces resolution by default with MSDEV */
	#ifndef TIMER_RES_DIVIDER
	#define TIMER_RES_DIVIDER 1000
	#endif
	#define SAMPLE_TIME_IMPLEMENTATION 1
#elif HAS_TIME_H
	#define NSECS_PER_SEC 1000000000
	#define EE_TIMER_TICKER_RATE 1000
	#define CORETIMETYPE struct timespec 
	#define GETMYTIME(_t) clock_gettime(CLOCK_REALTIME,_t)
	#define MYTIMEDIFF(fin,ini) ((fin.tv_sec-ini.tv_sec)*(NSECS_PER_SEC/TIMER_RES_DIVIDER)+(fin.tv_nsec-ini.tv_nsec)/TIMER_RES_DIVIDER)
	/* setting to 1/1000 of a second resolution by default with linux */
	#ifndef TIMER_RES_DIVIDER
	#define TIMER_RES_DIVIDER 1000000
	#endif
	#define SAMPLE_TIME_IMPLEMENTATION 1
#elif MY_TIME
    #define CTR_BA 0xf0000000
    #define BUS_FREQ_HZ 25000000
	#define NSECS_PER_SEC 1000000000
	#define EE_TIMER_TICKER_RATE 1000
	#define CORETIMETYPE unsigned int 
	#define GETMYTIME(_t) counter_get_msecs_par(CTR_BA,pn_get_cpuid(),_t)
	#define MYTIMEDIFF(fin,ini) ((fin)-(ini))
	#ifndef TIMER_RES_DIVIDER
	#define TIMER_RES_DIVIDER 1000000
	#endif
	#define SAMPLE_TIME_IMPLEMENTATION 1
#else
	#define SAMPLE_TIME_IMPLEMENTATION 0
#endif
#define EE_TICKS_PER_SEC (NSECS_PER_SEC / TIMER_RES_DIVIDER)

#if SAMPLE_TIME_IMPLEMENTATION
/** Define Host specific (POSIX), or target specific global time variables. */
static CORETIMETYPE start_time_val, stop_time_val;

/* Function: start_time
	This function will be called right before starting the timed portion of the benchmark.

	Implementation may be capturing a system timer (as implemented in the example code) 
	or zeroing some system parameters - e.g. setting the cpu clocks cycles to 0.
*/
void start_time(void) {
    counter_init(BUS_FREQ_HZ);
    //counter_set_cnt_div(CTR_BA, pn_get_cpuid(), 16);
	counter_reset(CTR_BA, pn_get_cpuid());
	counter_start(CTR_BA, pn_get_cpuid());
	GETMYTIME(&start_time_val );      
    //pn_hist_enable();

#if CALLGRIND_RUN
	CALLGRIND_START_INSTRUMENTATION
#endif
#if MICA
    asm volatile("int3");/*1 */
#endif
}
/* Function: stop_time
	This function will be called right after ending the timed portion of the benchmark.

	Implementation may be capturing a system timer (as implemented in the example code) 
	or other system parameters - e.g. reading the current value of cpu cycles counter.
*/
void stop_time(void) {
#if CALLGRIND_RUN
	 CALLGRIND_STOP_INSTRUMENTATION 
#endif
#if MICA
    asm volatile("int3");/*1 */
#endif
	GETMYTIME(&stop_time_val );      
    //pn_hist_disable();
}
/* Function: get_time
	Return an abstract "ticks" number that signifies time on the system.
	
	Actual value returned may be cpu cycles, milliseconds or any other value,
	as long as it can be converted to seconds by <time_in_secs>.
	This methodology is taken to accomodate any hardware or simulated platform.
	The sample implementation returns millisecs by default, 
	and the resolution is controlled by <TIMER_RES_DIVIDER>
*/
CORE_TICKS get_time(void) {
	CORE_TICKS elapsed=(CORE_TICKS)(MYTIMEDIFF(stop_time_val, start_time_val));
	return elapsed;
}
/* Function: time_in_secs
	Convert the value returned by get_time to seconds.

	The <secs_ret> type is used to accomodate systems with no support for floating point.
	Default implementation implemented by the EE_TICKS_PER_SEC macro above.
*/
secs_ret time_in_secs(CORE_TICKS ticks) {
	secs_ret retval=((secs_ret)ticks) / (secs_ret)EE_TICKS_PER_SEC;
	return retval;
}
#else 
#error "Please implement timing functionality in core_portme.c"
#endif /* SAMPLE_TIME_IMPLEMENTATION */

ee_u32 default_num_contexts=MULTITHREAD;

#if (MULTITHREAD>1)
//static volatile core_results **ppres;
static volatile core_results* ppres[MULTITHREAD];
static volatile int setup_results_pointer_complete = 0;
#endif

/* Function: portable_init
	Target specific initialization code 
	Test for some common mistakes.
*/
void portable_init(core_portable *p, int *argc, char *argv[])
{
#if PRINT_ARGS
	int i;
	for (i=0; i<*argc; i++) {
		ee_printf("Arg[%d]=%s\n",i,argv[i]);
	}
#endif
	if (sizeof(ee_ptr_int) != sizeof(ee_u8 *)) {
		ee_printf("ERROR! Please define ee_ptr_int to a type that holds a pointer!\n");
	}
	if (sizeof(ee_u32) != 4) {
		ee_printf("ERROR! Please define ee_u32 to a 32b unsigned type!\n");
	}
#if (MAIN_HAS_NOARGC && (SEED_METHOD==SEED_ARG))
	ee_printf("ERROR! Main has no argc, but SEED_METHOD defined to SEED_ARG!\n");
#endif
	
#if (MULTITHREAD>1) && (SEED_METHOD==SEED_ARG)
	{
		int nargs=*argc,i;
		if ((nargs>1) && (*argv[1]=='M')) {
			default_num_contexts=parseval(argv[1]+1);
			if (default_num_contexts>MULTITHREAD)
				default_num_contexts=MULTITHREAD;
			/* Shift args since first arg is directed to the portable part and not to coremark main */
			--nargs;
			for (i=1; i<nargs; i++)
				argv[i]=argv[i+1];
			*argc=nargs;
		}
	}
#endif /* sample of potential platform specific init via command line, reset the number of contexts being used if first argument is M<n>*/
	p->portable_id=1;

    int cpuid = pn_get_cpuid();
    if (cpuid == 0) {
        ee_printf("Running CoreMark with %d core(s)...\n", pn_get_ncpus());
    }
#if (MULTITHREAD>1)
    if (cpuid != 0) {
        // If we're not CPU0, then wait here for CPU#0 to set everything up...
        while(setup_results_pointer_complete == 0) ;
        while((*(ppres+cpuid))->port.thread_sig != SIGNO_THREAD_START) ;
        iterate((void *)(*(ppres+cpuid)));
        (*(ppres+cpuid))->port.thread_sig = SIGNO_THREAD_FINISHED;
        portable_fini(p);
    }/* else {
        ppres = (core_results **)portable_malloc(default_num_contexts*sizeof(core_results *));
        if (ppres == NULL) {
            ee_printf("Error allocating memory\n"); exit(1);
        }
    } */
#endif
}
/* Function: portable_fini
	Target specific final code 
*/
void portable_fini(core_portable *p)
{
	p->portable_id=0;

#if (MULTITHREAD>1)
    if (pn_get_cpuid() != 0) {
        // Do not leave until core #0 has finished printing results...
        wait_for_cpu(0);
        exit(0);
    } else {
        pn_sync_set(0);
        //portable_free(ppres);
    }
#else
    /*
    pn_stats_collect();
    //pn_stats_print();
    // Last one to print global stats...
    if (pn_get_cpuid() == pn_get_ncpus()-1) {
        pn_global_stats_collect();
        pn_global_stats_print();
    }
    */

    pn_sync_set(pn_get_cpuid());

    // Do not leave until all threads are done...
    wait_for_cpu(pn_get_ncpus()-1);
#endif
}

#if (MULTITHREAD>1)

/* Function: core_start_parallel
	Start benchmarking in a parallel context.
	
	Three implementations are provided, one using pthreads, one using fork and shared mem, and one using fork and sockets.
	Other implementations using MCAPI or other standards can easily be devised.
*/
/* Function: core_stop_parallel
	Stop a parallel context execution of coremark, and gather the results.
	
	Three implementations are provided, one using pthreads, one using fork and shared mem, and one using fork and sockets.
	Other implementations using MCAPI or other standards can easily be devised.
*/
#if USE_PTHREAD
ee_u8 core_start_parallel(core_results *res) {
	return (ee_u8)pthread_create(&(res->port.thread),NULL,iterate,(void *)res);
}
ee_u8 core_stop_parallel(core_results *res) {
	void *retval;
	return (ee_u8)pthread_join(res->port.thread,&retval);
}
#elif USE_FORK
static int key_id=0;
ee_u8 core_start_parallel(core_results *res) {
	key_t key=4321+key_id;
	key_id++;
	res->port.pid=fork();
	res->port.shmid=shmget(key, 8, IPC_CREAT | 0666);
	if (res->port.shmid<0) {
		ee_printf("ERROR in shmget!\n");
	}
	if (res->port.pid==0) {
		iterate(res);
		res->port.shm=shmat(res->port.shmid, NULL, 0);
		/* copy the validation values to the shared memory area  and quit*/
		if (res->port.shm == (char *) -1) {
			ee_printf("ERROR in child shmat!\n");
		} else {
			memcpy(res->port.shm,&(res->crc),8);
			shmdt(res->port.shm);
		}
		exit(0);
	}
	return 1;
}
ee_u8 core_stop_parallel(core_results *res) {
	int status;
	pid_t wpid = waitpid(res->port.pid,&status,WUNTRACED);
	if (wpid != res->port.pid) {
		ee_printf("ERROR waiting for child.\n");
		if (errno == ECHILD) ee_printf("errno=No such child %d\n",res->port.pid);
		if (errno == EINTR) ee_printf("errno=Interrupted\n");
		return 0;
	}
	/* after process is done, get the values from the shared memory area */
	res->port.shm=shmat(res->port.shmid, NULL, 0);
	if (res->port.shm == (char *) -1) {
		ee_printf("ERROR in parent shmat!\n");
		return 0;
	} 
	memcpy(&(res->crc),res->port.shm,8);
	shmdt(res->port.shm);
	return 1;
}
#elif USE_SOCKET
static int key_id=0;
ee_u8 core_start_parallel(core_results *res) {
	int bound, buffer_length=8;
	res->port.sa.sin_family = AF_INET;
	res->port.sa.sin_addr.s_addr = htonl(0x7F000001);
	res->port.sa.sin_port = htons(7654+key_id);
	key_id++;
	res->port.pid=fork();
	if (res->port.pid==0) { /* benchmark child */
		iterate(res);
		res->port.sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
		if (-1 == res->port.sock) /* if socket failed to initialize, exit */   {
			ee_printf("Error Creating Socket");
		} else {
			int bytes_sent = sendto(res->port.sock, &(res->crc), buffer_length, 0,(struct sockaddr*)&(res->port.sa), sizeof (struct sockaddr_in));
			if (bytes_sent < 0)
				ee_printf("Error sending packet: %s\n", strerror(errno));
			close(res->port.sock); /* close the socket */
		}
		exit(0);
	} 
	/* parent process, open the socket */
	res->port.sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	bound = bind(res->port.sock,(struct sockaddr*)&(res->port.sa), sizeof(struct sockaddr));
	if (bound < 0)
		ee_printf("bind(): %s\n",strerror(errno));
	return 1;
}
ee_u8 core_stop_parallel(core_results *res) {
	int status;
	int fromlen=sizeof(struct sockaddr);
	int recsize = recvfrom(res->port.sock, &(res->crc), 8, 0, (struct sockaddr*)&(res->port.sa), &fromlen);
	if (recsize < 0) {
		ee_printf("Error in receive: %s\n", strerror(errno));
		return 0;
	}
	pid_t wpid = waitpid(res->port.pid,&status,WUNTRACED);
	if (wpid != res->port.pid) {
		ee_printf("ERROR waiting for child.\n");
		if (errno == ECHILD) ee_printf("errno=No such child %d\n",res->port.pid);
		if (errno == EINTR) ee_printf("errno=Interrupted\n");
		return 0;
	}
	return 1;
}
#elif USE_PNTHREAD
static int i_start_core = 0;
/* On the ParaNut, CPU#0 first starts cores 1..n-1 since it will have to start
 * itself, too, after all other cores have been started. */
ee_u8 core_start_parallel(core_results *res) {
    if (i_start_core == 0) {
        // At first, redirect all result pointers...
        int i = 0;
        for (i = 0; i < default_num_contexts; i++) {
            *(ppres+i) = res+i;
            (*(ppres+i))->port.thread_sig = SIGNO_THREAD_CTXTINIT;
        }
        setup_results_pointer_complete = 1;
    }
    //*(ppres+i_start_core) = res;
    (*(ppres+i_start_core))->port.thread_sig = SIGNO_THREAD_START;
    if (i_start_core == default_num_contexts-1) {
        // CPU#0 has to start itself here at last.
        iterate((void *)(*(ppres)));
        (*(ppres))->port.thread_sig = SIGNO_THREAD_FINISHED;
    }
    ++i_start_core;

    return 0;
}

/* Stopping cores works the same as starting them: A strict order has to be
 * enforced since no synchronization primitives are implemented yet. */
static int i_stop_core = 0;
ee_u8 core_stop_parallel(core_results *res) {
    //(*res);
    //ee_printf("Waiting for core #%d\n", i_stop_core);
    while((*(ppres+i_stop_core))->port.thread_sig != SIGNO_THREAD_FINISHED) ;
    //ee_printf("Core #%d finished\n", i_stop_core);
    ++i_stop_core;

    return 0;
}
#else /* no standard multicore implementation */
#error "Please implement multicore functionality in core_portme.c to use multiple contexts."
#endif /* multithread implementations */
#endif
