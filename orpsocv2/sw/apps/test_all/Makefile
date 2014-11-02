SW_ROOT=../..

export BOARD=xilinx/ml509ddr

default: test_all

include $(SW_ROOT)/Makefile.inc

test_all: test_all.S
	#${OR32_AS} test_all.S -o test_all   # does not invoke the C preprocessor
	${OR32_CC} -o test_all -nostdlib test_all.S

clean:
	rm -f uart0.?x test_all
