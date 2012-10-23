/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2012 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

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
  //TRACE (tf, insn_top);
  //TRACE (tf, adr_top);
}


static bool IsJump (TWord insn) {
  TWord op6 = insn >> 26, op16 = insn >> 16;

  return op6 <= 0x04   // j, jal, bnf, bf
    || op6 == 0x11 || op6 == 0x12   // jr, jalr
    || op6 == 0x08     // sys, trap (also: msync, psync, csync)
    || op6 == 0x09;    // fre
  // TBD: include HALT ("l.nop 1")?
}


/*
void MIfu::StepBuffer () {
  int n;
  bool valid;

  // Determine 'valid' output...
  valid = (buf_top >= 1 && adr_top >= 2);
  //INFOF (("### bufTop = %i\n", bufTop));

  // Set outputs...
  ir = insn_buf[0];
  ir_valid = valid;
  pc = adr_buf[0];
  npc = adr_buf[1];
  ppc = adr_bufM1;
  //jal_adr = adr_buf[2];
  npc_valid = (adr_top >= 2); // jal_adr_valid = (adr_top >= 2);

  // Handle Jumps...
  if (jump == 1) {
    //INFO ("IFU: Caught Jump");
    ASSERT (adr_top >= 1);
    if (buf_top > 1) buf_top = 1;
    adr_buf[1] = jump_adr;  // this  moved down (TBD: clean up)
    ASSERT ((jump_adr.read () & 3) == 0);
    adr_top = 2;
  }

  // Determine next buffer state...
  if (valid) {
  
    // Consume a queue item...
    if (next == 1) {
      ASSERT (buf_top >= 1);
      adr_bufM1 = adr_buf[0];
      for (n = 0; n < adr_top-1; n++) {
        insn_buf[n] = insn_buf[n+1];
        adr_buf[n] = adr_buf[n+1];
      }
      buf_top--;
      adr_top--;
    }
  }

  // Create next loadable adress...
  if (adr_top < IFU_BUF_SIZE) {
    adr_buf[adr_top] = adr_buf[adr_top-1] + 4;
    adr_top++;
  }

  // Load jump adress if applicable (TBD: clean up)...
  if (jump == 1) adr_buf[1] = jump_adr;
}


void MIfu::MainThread () {
  int n;

  // Reset...
  buf_top = 0;
  adr_buf[0] = 0x100;
  adr_top = 1;

  // - to EXU
  ppc = 0;

  // - to memory
  rp_rd = 0;

  // Main loop...
  while (1) {
    StepBuffer ();
    wait ();

    // Reload actions...
    if (adr_top > buf_top                 // new adress available?
        && buf_top < IFU_BUF_SIZE    // space available?
        && (buf_top < 2 || !IsJump (insn_buf[buf_top-2]))) {     // jump pending? (-> load delay slot insn, but nothing more)
      rp_adr = adr_buf[buf_top];
      //INFOF (("### Loading adr %x, buf_top = %i, adr_top = %i", adrBuf[buf_top], buf_top, adr_top));
      rp_rd = 1;
      while (rp_ack == 0) {
        StepBuffer ();
        wait ();
      }
      rp_rd = 0;
      insn_buf[buf_top] = rp_data;
      buf_top++;
    }
  }
}
*/


void MIfu::OutputMethod () {

  // Towards EXU...
  ir = insn_buf[1];
  ir_valid = (insn_top > 1);
  ppc = adr_buf[0];
  pc = adr_buf[1];
  npc = adr_buf[2];
  npc_valid = (insn_top > 2);

  // Towards MemU...
//  rp_rd = 0;
//  rp_adr = 0;  // don't care
//  if (adr_top > insn_top && insn_top < IFU_BUF_SIZE-1           // Space & adress available?
//      && rp_ack == 0
//      && !(insn_top > 2 && IsJump(insn_buf[insn_top-2]))) {   // no jump pending?
//    rp_rd = 1;
//    rp_adr = adr_buf[insn_top];
//  }

  //rp_rd = (state_reg == s_ifu_reading) ? 1 : 0;
  rp_adr = adr_buf[insn_top];
}


void MIfu::TransitionMethod () {
  int n, insn_top_var, adr_top_var;
  bool ir_valid_var;

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
  switch (state_reg.read ()) {
    case s_ifu_idle:
      if (adr_top_var > insn_top && insn_top_var < IFU_BUF_SIZE           // Adress & space available?
	  && !(insn_top_var > 2 && IsJump(insn_buf[insn_top-2]))) {   // no jump pending?
	rp_rd = 1;
        //rp_adr = adr_buf[insn_top_var];
	state_reg = s_ifu_reading;
      }
      break;
    case s_ifu_reading:
      if (rp_ack == 1) {
        rp_rd = 0;
	state_reg = s_ifu_idle;
      }
      break;
  }

  // Handle reset (must dominate)...
  if (reset == 1) {
    insn_top_var = 1;
    adr_buf[0] = 0x100 - 4;
    adr_top_var = 1;
    state_reg = s_ifu_idle;
    rp_rd = 0;
  }

  // Write back counter values to registers...
  insn_top = insn_top_var;
  adr_top = adr_top_var;
}
