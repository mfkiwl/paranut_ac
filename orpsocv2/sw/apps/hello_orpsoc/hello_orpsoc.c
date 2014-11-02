#include <board.h>
#include <uart.h>
#include <printf.h>

int main () {
    unsigned int n;
    unsigned char dips, btns;
    volatile unsigned char *gpio_data_reg_adr = (unsigned char*) 0x91000000;
    volatile unsigned char *gpio_dir_reg_adr = gpio_data_reg_adr + 3;

    *(gpio_dir_reg_adr) = 0xff;
    *(gpio_dir_reg_adr+1) = 0x1f;
    *(gpio_dir_reg_adr+2) = 0x00;

    uart_init(DEFAULT_UART);

    while (1) {
        if (++n % 10000 == 0)
            printf ("%2u: Hello ORPSoC!\n", n);
        dips = *(gpio_data_reg_adr+2) >> 2 | 0xc0;
        btns = *(gpio_data_reg_adr+1) >> 5;
        btns |= *(gpio_data_reg_adr+2) << 3;
        *(gpio_data_reg_adr) = dips;
        *(gpio_data_reg_adr+1) = btns;
    }
    return 0;
}
