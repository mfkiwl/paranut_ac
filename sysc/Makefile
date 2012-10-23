CFLAGS = -g -O3 -I/usr/include/systemc-2.2 # -Wfatal-errors
LDFLAGS = -lsystemc-2.2 # -Wfatal-errors

MEMU_TB_SRC = base.cpp lfsr.cpp memu.cpp memory.cpp uart16450.cpp peripherals.cpp memu_tb.cpp
MEMU_TB_OBJ = base.o lfsr.o memu.o memory.o uart16450.o peripherals.o memu_tb.o

PARANUT_SRC = base.cpp lfsr.cpp ifu.cpp exu.cpp lsu.cpp memu.cpp paranut.cpp
PARANUT_OBJ = base.o lfsr.o ifu.o exu.o lsu.o memu.o paranut.o

PARANUT_TB_SRC = $(PARANUT_SRC) memory.cpp uart16450.cpp peripherals.cpp paranut_tb.cpp
PARANUT_TB_OBJ = $(PARANUT_OBJ) memory.o uart16450.o peripherals.o paranut_tb.o

TEST_APP = test_all
TEST_APP_DIR = ../sw/test_all


paranut_tb: $(PARANUT_TB_OBJ)
	@echo; echo "### Linking"; echo
	g++ $(LDFLAGS) -o paranut_tb $(PARANUT_TB_OBJ)

memu_tb: $(MEMU_TB_OBJ)
	@echo; echo "### Linking"; echo
	g++ $(LDFLAGS) -o memu_tb $(MEMU_TB_OBJ)

sim: paranut_tb test_app
	@echo; echo "### Simulating..."; echo
	./paranut_tb $(TEST_APP_DIR)/$(TEST_APP)

test_app:
	@echo; echo "### Making test application"; echo
	+make -C $(TEST_APP_DIR) $(TEST_APP)

depend:
	makedepend -Y $(PARANUT_TB_SRC) $(MEMU_TB_SRC) # -- $(CFLAGS) -- $(PN_SRC) $(MEMU_TB_SRC)

%.o:	%.cpp
	g++ -c $(CFLAGS) $<

clean:
	rm -f *.[ao] core paranut_tb paranut_tb.vcd memu_tb memu_tb.vcd


# DO NOT DELETE

base.o: base.h
lfsr.o: lfsr.h base.h
ifu.o: ifu.h base.h
exu.o: exu.h base.h memory.h config.h
lsu.o: lsu.h base.h config.h
memu.o: memu.h base.h config.h lfsr.h
paranut.o: paranut.h memu.h base.h config.h ifu.h lsu.h exu.h
memory.o: memory.h base.h config.h or32-elf.h
uart16450.o: uart16450.h base.h
peripherals.o: peripherals.h memory.h base.h config.h uart16450.h
paranut_tb.o: peripherals.h memory.h base.h config.h uart16450.h paranut.h
paranut_tb.o: memu.h ifu.h lsu.h exu.h
base.o: base.h
lfsr.o: lfsr.h base.h
memu.o: memu.h base.h config.h lfsr.h
memory.o: memory.h base.h config.h or32-elf.h
uart16450.o: uart16450.h base.h
peripherals.o: peripherals.h memory.h base.h config.h uart16450.h
memu_tb.o: memu.h base.h config.h peripherals.h memory.h uart16450.h
