test_all: test_all.S
	or32-elf-gcc -o test_all -nostdlib test_all.S
	#or32-elf-as test_all.S -o test_all   # does not invoke the C preprocessor

sim: test_all
	or32-elf-sim -i -f ../or1ksim-paranut.cfg test_all < sim.in
	echo

clean:
	rm -f uart0.?x test_all
