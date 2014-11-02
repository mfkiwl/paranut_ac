export
SCRIPTS_DIR=../../../../bin
ENTITY_NAME=mparanut
WORKLIB=paranut
#NEED_UNISIM=1

# Simulation...
VHDL_SRC_PATH=../../paranut:../../uart_16750:../../counter
MEMU_OBJ = mmemu.o mtagram.o mbankram.o mbusif.o mreadport.o mwriteport.o marbiter.o
PARANUT_OBJ = $(MEMU_OBJ) mem_inferred.o mexu.o mifu.o mifu_bs.o mlsu.o mlsu_simple.o mparanut.o shift32.o mult32x32s.o mul_inferred.o
SIM_MODULE_OBJ = $(ENTITY_NAME)_tb.o $(PARANUT_OBJ) wb_memory.o wb_uart.o slib_clock_div.o slib_counter.o slib_edge_detect.o slib_fifo.o slib_input_filter.o slib_input_sync.o slib_mv_filter.o txt_util.o uart_baudgen.o uart_interrupt.o uart_receiver.o uart_transmitter.o wb8_uart_16750.o mhistogram.o wb_counter_wrapper.o wb_counter.o counter_top.o

# Synthesis...
XST_MODULE_SRC = $(ENTITY_NAME).vhd types.vhd paranut_config.vhd paranut_lib.vhd orbis32.vhd memu.vhd mmemu.vhd ifu.vhd mifu.vhd mifu_bs.vhd lsu.vhd mlsu.vhd memu_lib.vhd mem_inferred.vhd mul_tech.vhd shift32.vhd mult32x32s.vhd mul_inferred.vhd exu.vhd mexu.vhd regfile.vhd mem_tech.vhd mtagram.vhd mbankram.vhd mreadport.vhd mwriteport.vhd marbiter.vhd mbusif.vhd lfsr.vhd histogram.vhd mhistogram.vhd
IOBUF="no"
XILINX_DEVICE_PART=xc5vlx110t-ff1136-1
#XILINX_DEVICE_PART=xc3s700a-fg484-4

################################################################################
include $(SCRIPTS_DIR)/Makefile.inc
