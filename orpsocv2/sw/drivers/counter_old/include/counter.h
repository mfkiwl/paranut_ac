#ifndef COUNTER_H
#define COUNTER_H

#define REG_RESET_OFFSET 0x0
#define REG_ENABLE_OFFSET 0x4
#define REG_CNTDIV_OFFSET 0x40
#define REG_CNTVAL_OFFSET 0x80

#define COUNTER_READ_SLV_REG(BaseAddress, RegOffset) \
 	(*(unsigned int volatile *)((BaseAddress) + (RegOffset)))

#define COUNTER_WRITE_SLV_REG(BaseAddress, RegOffset, Value) \
 	(*(unsigned int volatile *)((BaseAddress) + (RegOffset)) = Value)

#ifdef __cplusplus
extern "C" {
#endif
void counter_init(int _bus_freq_hz);
void counter_reset(unsigned int baseaddr, unsigned int counter);
void counter_start(unsigned int baseaddr, unsigned int counter);
void counter_stop(unsigned int baseaddr, unsigned int counter);
unsigned int counter_get_cnt_div(unsigned int baseaddr, unsigned int counter);
int counter_set_cnt_div(unsigned int baseaddr, unsigned int counter, unsigned int div);
unsigned counter_get_cnt(unsigned int baseaddr, unsigned int counter);
unsigned coutner_get_msecs(unsigned int baseaddr, unsigned int counter);
void coutner_get_cnt_par(unsigned int baseaddr, unsigned int counter, unsigned int*);
void coutner_get_msecs_par(unsigned int baseaddr, unsigned int counter, unsigned int*);
#ifdef __cplusplus
}
#endif

#endif /** COUNTER_H */
