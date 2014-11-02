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
	COUNTER_WRITE_SLV_REG(baseaddr, counter, REG_CTRL_OFFSET, 0x1);
}

void counter_start(unsigned int baseaddr, unsigned int counter)
{
    unsigned int val;
	COUNTER_WRITE_SLV_REG(baseaddr, counter, REG_CTRL_OFFSET, 0x2);
}

void counter_stop(unsigned int baseaddr, unsigned int counter)
{
    unsigned int val;
	COUNTER_WRITE_SLV_REG(baseaddr, counter, REG_CTRL_OFFSET, 0x0);
}

unsigned int counter_get_cnt_div(unsigned int baseaddr, unsigned int counter)
{
	return (unsigned)COUNTER_READ_SLV_REG(baseaddr, counter, REG_CNTDIV_OFFSET);
}

int counter_set_cnt_div(unsigned int baseaddr, unsigned int counter, unsigned int div)
{
	COUNTER_WRITE_SLV_REG(baseaddr, counter, REG_CNTDIV_OFFSET, div);
    if (div != (unsigned int) COUNTER_READ_SLV_REG(baseaddr, counter, REG_CNTDIV_OFFSET))
        return -1;
    else {
        pre_div[counter] = div;
        return 0;
    }
}

unsigned counter_get_cnt(unsigned int baseaddr, unsigned int counter)
{
	return (unsigned)COUNTER_READ_SLV_REG(baseaddr, counter, REG_CNTVAL_OFFSET);
}

unsigned counter_get_msecs(unsigned int baseaddr, unsigned int counter)
{
    unsigned int div = pre_div[counter] ? pre_div[counter] : 1;
	unsigned cnt = (unsigned)COUNTER_READ_SLV_REG(baseaddr, counter, REG_CNTVAL_OFFSET);
	return (cnt) / (bus_freq_hz / 1000) * div;
}

void counter_get_cnt_par(unsigned int baseaddr, unsigned int counter, unsigned int* time)
{
	*time = (unsigned)COUNTER_READ_SLV_REG(baseaddr, counter, REG_CNTVAL_OFFSET);
}

void counter_get_msecs_par(unsigned int baseaddr, unsigned int counter, unsigned int* time)
{
    unsigned int div = pre_div[counter] ? pre_div[counter] : 1;
	unsigned cnt = (unsigned)COUNTER_READ_SLV_REG(baseaddr, counter, REG_CNTVAL_OFFSET);
	*time = (cnt) / (bus_freq_hz / 1000) * div;
}
