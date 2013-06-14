CC = or32-elf-gcc

CFLAGS = -g -O2 -Wa,-alhn=$<.s
#LDFLAGS = -mor32-newlib-uart 
LDFLAGS = -mnewlib -mboard=or1ksim-uart  # orpsocrefdesign

hello_newlib: hello_newlib.o
	$(CC) -o $@ $< $(LDFLAGS)

sim: hello_newlib
	or32-elf-sim -f ../or1ksim-paranut.cfg hello_newlib

%.o:	%.c
	$(CC) -c $(CFLAGS) $<

clean:
	rm -f *.o *.s hello_newlib uart0.tx uart0.rx
