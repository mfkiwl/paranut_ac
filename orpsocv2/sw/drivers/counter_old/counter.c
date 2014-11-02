/*****************************************************************************
 * Filename:          /rzhome/mn/mikkl/etc/arbad/edk_user_repository/MyProcessorIPLib/drivers/counter_v1_00_a/src/counter.c
 * Version:           1.00.a
 * Description:       counter Driver Source File
 * Date:              Wed May 18 12:38:51 2011 (by Create and Import Peripheral Wizard)
 *****************************************************************************/


/***************************** Include Files *******************************/

#include "counter.h"

/************************** Function Definitions ***************************/

static unsigned int pre_div[32];
static int bus_freq_hz;

void counter_init(int _bus_freq_hz)
{
    bus_freq_hz = _bus_freq_hz;
}

void counter_reset(unsigned int baseaddr, unsigned int counter)
{
    // auto-clearing reset
	COUNTER_WRITE_SLV_REG(baseaddr, REG_RESET_OFFSET, 0x1<<counter);
}

void counter_start(unsigned int baseaddr, unsigned int counter)
{
    unsigned int val;
    val = COUNTER_READ_SLV_REG(baseaddr, REG_ENABLE_OFFSET);
	COUNTER_WRITE_SLV_REG(baseaddr, REG_ENABLE_OFFSET, val | 0x1<<counter);
}

void counter_stop(unsigned int baseaddr, unsigned int counter)
{
    unsigned int val;
    val = COUNTER_READ_SLV_REG(baseaddr, REG_ENABLE_OFFSET);
	COUNTER_WRITE_SLV_REG(baseaddr, REG_ENABLE_OFFSET, val & ~(0x1<<counter));
}

unsigned int counter_get_cnt_div(unsigned int baseaddr, unsigned int counter)
{
	return (unsigned)COUNTER_READ_SLV_REG(baseaddr, REG_CNTDIV_OFFSET+counter*4);
}

int counter_set_cnt_div(unsigned int baseaddr, unsigned int counter, unsigned int div)
{
	COUNTER_WRITE_SLV_REG(baseaddr, REG_CNTDIV_OFFSET+counter*4, div);
    if (div != (unsigned int) COUNTER_READ_SLV_REG(baseaddr, REG_CNTDIV_OFFSET+counter*4))
        return -1;
    else {
        pre_div[counter] = div;
        return 0;
    }
}

unsigned counter_get_cnt(unsigned int baseaddr, unsigned int counter)
{
	return (unsigned)COUNTER_READ_SLV_REG(baseaddr, REG_CNTVAL_OFFSET+counter*4);
}

unsigned counter_get_msecs(unsigned int baseaddr, unsigned int counter)
{
    unsigned int div = pre_div[counter] ? pre_div[counter] : 1;
	unsigned cnt = (unsigned)COUNTER_READ_SLV_REG(baseaddr, REG_CNTVAL_OFFSET+counter*4);
	return (cnt) / (bus_freq_hz / 1000) * div;
}

void counter_get_cnt_par(unsigned int baseaddr, unsigned int counter, unsigned int* time)
{
	*time = (unsigned)COUNTER_READ_SLV_REG(baseaddr, REG_CNTVAL_OFFSET+counter*4);
}

void counter_get_msecs_par(unsigned int baseaddr, unsigned int counter, unsigned int* time)
{
    unsigned int div = pre_div[counter] ? pre_div[counter] : 1;
	unsigned cnt = (unsigned)COUNTER_READ_SLV_REG(baseaddr, REG_CNTVAL_OFFSET+counter*4);
	*time = (cnt) / (bus_freq_hz / 1000) * div;
}
