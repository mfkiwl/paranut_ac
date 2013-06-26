/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2012 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This file contains the configuration options for the ParaNut.

 *************************************************************************/


#ifndef _CONFIG_
#define _CONFIG_


// **************** General options ***********************


#define CPU_CORES_LD 0
#define CPU_CORES (1 << CPU_CORES_LD)        // 4

#define MEM_SIZE (32 * MB)


static inline bool AdrIsCached (TWord adr) { return adr < MEM_SIZE; }
static inline bool AdrIsSpecial (TWord adr) { return (adr & 0xf0000000) == 0x90000000; }    // These are I/O adresses




// ********************* MemU *****************************


#define CACHE_BANKS_LD 2    // a cache line has a size of CACHE_BANKS words
#define CACHE_BANKS (1 << CACHE_BANKS_LD)    // 4

#define CACHE_SETS_LD 9     // number of cache sets
#define CACHE_SETS (1 << CACHE_SETS_LD)    // 512

#define CACHE_WAYS_LD 0     // associativity; supported values are 0..2, corresponding to 1/2/4-way set-associativity
#define CACHE_WAYS (1 << CACHE_WAYS_LD)
#define CACHE_REPLACE_LRU 1   // 0 = random replacement, 1 = LRU replacement

#define ARBITER_METHOD 7    // > 0: round-robin arbitration, switches every (1 << ARBITER_METHOD) clocks
                            // < 0: pseudo-random arbitration (LFSR-based)


// ***** auto-generated *****


#define WPORTS CPU_CORES
#define RPORTS (2 * CPU_CORES)

#define CACHE_SIZE (CACHE_SETS * CACHE_WAYS * CACHE_BANKS * 4)



#endif
