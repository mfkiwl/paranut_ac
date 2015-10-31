CC = or1k-elf-gcc

OR32SUPPORT = $(PWD)/openrisc/orpsocv2/sw/support

CFLAGS = -g -O2 -I$(OR32SUPPORT) -Wa,-alhn=$<.s
LDFLAGS = -T$(OR32SUPPORT)/orp.ld $(OR32SUPPORT)/reset-nocache.o $(OR32SUPPORT)/except.o $(OR32SUPPORT)/libsupport.a


hello: hello.o $(OR32SUPPORT)/libsupport.a
	$(CC) -o $@ $< $(LDFLAGS)

sim-hello: hello
	or32-elf-sim -f ../or1ksim-paranut.cfg hello

$(OR32SUPPORT)/libsupport.a:
	export UART_PRINTF=1 && make -C $(OR32SUPPORT) all

%.o:	%.c
	$(CC) -c $(CFLAGS) $<

clean:
	rm -f *.o *.s hello uart0.tx uart0.rx

clean-all: clean
	make -C $(OR32SUPPORT) clean
