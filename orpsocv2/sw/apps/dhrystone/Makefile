CC = or32-elf-gcc

CFLAGS = -O3 -mhard-mul -msoft-div -msoft-float
#LDFLAGS = -mor32-newlib-uart 
LDFLAGS = -mnewlib -mboard=ml509_25

INCLUDES = -I../../drivers/counter/include -I../../drivers/paranut/include
VPATH = ../../drivers/counter:../../drivers/paranut

#dhry: dhry_1.o dhry_2.o pn_dhry.o counter.o paranut_hist.o
dhry: dhry_1.o dhry_2.o pn_dhry.o counter.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o:	%.c dhry.h
	$(CC) -c $(INCLUDES) $(CFLAGS) $<

clean:
	rm -f *.o *.s dhry
