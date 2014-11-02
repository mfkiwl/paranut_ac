#ifndef COUNTER_H
#define COUNTER_H

#define COUNTER_mReadSlaveReg(BaseAddress, RegOffset) \
 	(*((BaseAddress) + (RegOffset)))

#define COUNTER_mWriteSlaveReg(BaseAddress, RegOffset, Value) \
 	((*((BaseAddress) + (RegOffset))) = Value)

XStatus COUNTER_SelfTest(void * baseaddr_p);
void reset_cnt(unsigned int baseaddr);
void enable_cnt(unsigned int baseaddr);
void disable_cnt(unsigned int baseaddr);
unsigned int get_cnt_div(unsigned int baseaddr);
int set_cnt_div(unsigned int baseaddr, unsigned int div);
unsigned get_cnt(unsigned int baseaddr);
unsigned get_msecs(unsigned int baseaddr);
void get_cnt_par(unsigned int baseaddr, unsigned int*);
void get_msecs_par(unsigned int baseaddr, unsigned int*);

#endif /** COUNTER_H */
