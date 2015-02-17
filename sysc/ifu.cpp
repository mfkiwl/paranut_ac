/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2015 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

 *************************************************************************/


#include "ifu.h"

#include <assert.h>


void MIfu::Trace (sc_trace_file *tf, int level) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports...
  TRACE (tf, clk);
  TRACE (tf, reset);
  //   to MEMU (read port)...
  TRACE (tf, rp_rd);
  TRACE (tf, rp_ack);
  TRACE (tf, rp_adr);
  TRACE (tf, rp_data);
  //   to EXU ...
  TRACE (tf, next);
  TRACE (tf, jump);
  TRACE (tf, jump_adr);
  TRACE (tf, ir);
  TRACE (tf, ppc);
  TRACE (tf, pc);
  TRACE (tf, npc);
  TRACE (tf, ir_valid);
  TRACE (tf, npc_valid);
  //   internal registers...
  TRACE_BUS (tf, insn_buf, IFU_BUF_SIZE);
  TRACE_BUS (tf, adr_buf, IFU_BUF_SIZE);
  TRACE (tf, insn_top);
  TRACE (tf, adr_top);
  TRACE (tf, last_rp_ack);
}


static bool IsJump (TWord insn) {
  TWord op6 = insn >> 26, op16 = insn >> 16;

  return op6 <= 0x04   // j, jal, bnf, bf
    || op6 == 0x11 || op6 == 0x12   // jr, jalr
    || op6 == 0x08     // sys, trap (also: msync, psync, csync)
    || op6 == 0x09;    // fre
  // TBD: include HALT ("l.nop 1")?
}


void MIfu::OutputMethod () {

  // Towards EXU...
  ir = insn_buf[1];
  ir_valid = (insn_top > 1);
  ppc = adr_buf[0];
  pc = adr_buf[1];
  npc = adr_buf[2];
  npc_valid = (adr_top > 2);

  // Towards MemU...
  //rp_adr = adr_buf[insn_top];
}


void MIfu::TransitionMethod () {
  int n, insn_top_var, adr_top_var, ofs, next_insn_top_var;
  bool ir_valid_var, have_jump;

  insn_top_var = insn_top;
  adr_top_var = adr_top;
  ir_valid_var = (insn_top_var > 1);

  // Shift buffer if 'next' is asserted...
  if (next == 1) {
    for (n = 0; n < IFU_BUF_SIZE-1; n++) {
      insn_buf[n] = insn_buf[n+1];
      adr_buf[n] = adr_buf[n+1];
    }
    if (insn_top_var > 0) insn_top_var--;
    if (adr_top_var > 0) adr_top_var--;
  }

  // Generate new adress...
  if (adr_top_var < IFU_BUF_SIZE) {
    adr_buf[adr_top_var] = adr_buf[adr_top_var - (next == 0 ? 1 : 0)] + 4;
    adr_top_var++;
  }

  // Handle jump ...
  if (jump == 1) {
    ASSERT ((jump_adr.read () & 3) == 0);
    // now '*_buf[1]' contain the next (delay slot) instruction
    if (insn_top_var > 2) insn_top_var = 2;
    adr_buf[2] = jump_adr;
    adr_top_var = 3;
  }

  // Store new memory data if available...
  last_rp_ack = rp_ack;
  if (last_rp_ack == 1) {
    ASSERT (insn_top_var < IFU_BUF_SIZE);
    insn_buf[insn_top_var] = rp_data;
    insn_top_var++;
  }

  // Issue new memory read request if appropriate...
  rp_rd = 0; // default
  ofs = (next == 1 ? 1 : 0); // offset to where to find the current top instruction in 'insn_buf'
  next_insn_top_var = insn_top_var;
  if (rp_ack == 1) next_insn_top_var++;
  if (adr_top_var > next_insn_top_var && next_insn_top_var+ofs < IFU_BUF_SIZE        // Adress & space available?
      && !(next_insn_top_var >= 2 && IsJump(insn_buf[next_insn_top_var+ofs-2]))) {   // no jump pending?
    rp_adr = adr_buf[next_insn_top_var+ofs];
    rp_rd = 1;
  }

  // Handle reset (must dominate)...
  if (reset == 1) {
    insn_top_var = 1;
    adr_buf[0] = 0x100 - 4;
    adr_top_var = 1;
    rp_rd = 0;
  }

  // Write back counter values to registers...
  insn_top = insn_top_var;
  adr_top = adr_top_var;
}
