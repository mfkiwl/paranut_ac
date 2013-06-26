CC = or32-elf-gcc

CFLAGS = -g -O3 -Wa,-alhn=$<.s
#LDFLAGS = -mor32-newlib-uart 
LDFLAGS = -mnewlib -mboard=or1ksim	 # -mboard=or1ksim-uart

dhry: dhry_1.o dhry_2.o pn_dhry.o 
	$(CC) -o $@ dhry_1.o dhry_2.o pn_dhry.o $(LDFLAGS)

sim-or: dhry
	or32-elf-sim -f ../or1ksim-paranut.cfg dhry

sim-paranut: dhry
	+make -C ../../sysc paranut_tb
	../../sysc/paranut_tb -t0 dhry

%.o:	%.c dhry.h
	$(CC) -c $(CFLAGS) $<

clean:
	rm -f *.o *.s hello_newlib uart0.tx uart0.rx
