CC = or32-elf-gcc

CFLAGS = -g -O3
#LDFLAGS = -mor32-newlib-uart 
LDFLAGS = -mnewlib -mboard=ml509_66

INCLUDES = -I../../drivers/counter/include -I../../drivers/paranut/include
VPATH = ../../drivers/counter:../../drivers/paranut

dhry: dhry_1.o dhry_2.o pn_dhry.o counter.o paranut.o paranut_hist.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o:	%.c dhry.h
	$(CC) -c $(INCLUDES) $(CFLAGS) $<

clean:
	rm -f *.o *.s dhry
