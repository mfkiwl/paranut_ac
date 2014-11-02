/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This file contains platform-specific functions for the
    Dhrystone benchmark.

 *************************************************************************/

#define CTR_BA 0xf0000000
#define BUS_FREQ_HZ 66000000

#include "dhry.h"
#include "counter.h"

static int init_done = 0;

long time ()
{
    if (init_done == 0) {
        counter_init(BUS_FREQ_HZ);
        counter_reset(CTR_BA, 0);
        counter_start(CTR_BA, 0);
        init_done = 1;
    }
    return (long) counter_get_msecs(CTR_BA, 0);
}
