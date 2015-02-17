# This file is part of the ParaNut project.
# 
# (C) 2010-2015 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
#     Hochschule Augsburg, University of Applied Sciences
# 
# Description:
#   This module contains various types, constants and helper functions
#   for the SystemC model of ParaNut.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

CFLAGS = -g -O3 -I/opt/systemc-2.3.1/include # -Wfatal-errors
LDFLAGS = -L/opt/systemc-2.3.1/lib-linux64 -lsystemc-2.3.1 # -Wfatal-errors

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
	./paranut_tb -c -m 0x700 0x7ff $(TEST_APP_DIR)/$(TEST_APP)

test_app: paranut_tb
	@echo; echo "### Making test application"; echo
	+make -C $(TEST_APP_DIR) $(TEST_APP)

hello_newlib: paranut_tb
	@echo; echo "### Making 'hello_newlib"; echo
	+make -C ../sw/hello_newlib hello_newlib
	@echo; echo "### Simulating..."; echo
	./paranut_tb ../sw/hello_newlib/hello_newlib

dhrystone: paranut_tb
	@echo; echo "### Making 'dhrystone'"; echo
	+make -C ../sw/dhrystone dhry
	@echo; echo "### Simulating..."; echo
	./paranut_tb -t0 ../sw/dhrystone/dhry

coremark: paranut_tb
	@echo; echo "### Making 'coremark'"; echo
	+make -C ../sw/coremark_v1.0 compile PORT_DIR=paranut_sim ITERATIONS=2
	@echo; echo "### Simulating..."; echo
	./paranut_tb -t0 ../sw/coremark_v1.0/coremark.exe
	
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
