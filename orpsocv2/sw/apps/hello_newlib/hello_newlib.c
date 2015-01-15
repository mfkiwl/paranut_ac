#include <stdio.h>
#include <or1k-support.h>
#include "counter.h"

#define CTR_BA 0xf0000000

extern unsigned long _board_clk_freq;

int main () {
    //or1k_icache_disable();
    //or1k_dcache_disable();

    unsigned int n;
    unsigned char dips, btns;
    unsigned int cnt_div = 4;
    volatile unsigned char *gpio_data_reg_adr = (unsigned char*) 0x91000000;
    volatile unsigned char *gpio_dir_reg_adr = gpio_data_reg_adr + 3;

    *(gpio_dir_reg_adr) = 0xff;
    *(gpio_dir_reg_adr+1) = 0x1f;
    *(gpio_dir_reg_adr+2) = 0x00;

    //counter_start(CTR_BA);
    counter_init(_board_clk_freq);

    while (1) {
        n = counter_get_msecs(CTR_BA, 0);
        printf ("%u: Hello Newlib on ORPSoC!\n", n);
        dips = *(gpio_data_reg_adr+2) >> 2 | 0xc0;
        btns = *(gpio_data_reg_adr+1) >> 5;
        btns |= *(gpio_data_reg_adr+2) << 3;

        *(gpio_data_reg_adr) = dips;
        *(gpio_data_reg_adr+1) = btns;

        if ((btns & 0x1) == 0x1)
            counter_reset(CTR_BA, 0);
        if ((btns & 0x2) == 0x2)
            counter_stop(CTR_BA, 0);
        if ((btns & 0x8) == 0x8) {
            counter_set_cnt_div(CTR_BA, 0, cnt_div);
            counter_start(CTR_BA, 0);
        }
        if ((btns & 0x4) == 0x4) {
            if (cnt_div != 0) {
                cnt_div -= 1;
                counter_set_cnt_div(CTR_BA, 0, cnt_div);
            }
        }
        if ((btns & 0x10) == 0x10) {
            if (cnt_div != 255) {
                cnt_div += 1;
                counter_set_cnt_div(CTR_BA, 0, cnt_div);
            }
        }
    }
  //for (n = 1; n <= 9; n++)
  //  printf ("%2i. Hello World!\n", n);
  return 0;
}

