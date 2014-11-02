CC = or32-elf-gcc

CFLAGS = -O2
#LDFLAGS = -mor32-newlib-uart 
LDFLAGS = -mnewlib -mboard=ml509_25

INCLUDE_PATH = ../../drivers/counter/include
VPATH = ../../drivers/counter

hello_newlib: hello_newlib.o counter.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o:	%.c
	$(CC) -c $(CFLAGS) -I$(INCLUDE_PATH) $<

clean:
	rm -f *.o *.s hello_newlib
