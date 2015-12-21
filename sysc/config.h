/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2015 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This file contains the configuration options for the ParaNut.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

 *************************************************************************/


#ifndef _CONFIG_
#define _CONFIG_


// **************** General options ***********************


#define CPU_CORES_LD 1
#define CPU_CORES (1 << CPU_CORES_LD)        // 4
#define CPU_CORES_CAP (1<<0 | 1<<1)		//maybe insert code to make sure no more bits are set than CPUs are available (#if..)

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
