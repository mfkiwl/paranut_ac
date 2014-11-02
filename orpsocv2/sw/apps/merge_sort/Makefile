CC = or32-elf-gcc

CFLAGS = -O3
#LDFLAGS = -mor32-newlib-uart 
#LDFLAGS = -mnewlib -mboard=ml509_25
LDFLAGS = -mnewlib -mboard=or1ksim

INCLUDES = -I../../drivers/counter/include -I../../drivers/paranut/include
VPATH = ../../drivers/counter ../../drivers/paranut

all: merge_sort merge_sort2 quicksort

merge_sort: merge_sort.o counter.o paranut.o paranut_hist.o
	$(CC) -o $@ $^ $(LDFLAGS)

merge_sort2: merge_sort2.o counter.o paranut.o paranut_hist.o
	$(CC) -o $@ $^ $(LDFLAGS)

quicksort: quicksort.o counter.o paranut.o paranut_hist.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o:	%.c
	$(CC) -c $(CFLAGS) $(INCLUDES) $<

clean:
	rm -f *.o *.s merge_sort merge_sort2 quicksort
