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
  TRACE (tf, jal_adr);
  TRACE (tf, ir_valid);
  TRACE (tf, npc_valid);
}


static bool IsJump (TWord insn) {
  TWord op6 = insn >> 26, op16 = insn >> 16;

  return op6 <= 0x04   // j, jal, bnf, bf
    || op6 == 0x11 || op6 == 0x12   // jr, jalr
    || op6 == 0x08     // sys, trap (also: msync, psync, csync)
    || op6 == 0x09;    // fre
  // TBD: include HALT ("l.nop 1")
}


void MIfu::StepBuffer () {
  int n;
  bool valid;

  // Determine 'valid' output...
  valid = (bufTop >= 1 && adrTop >= 2);
  //INFOF (("### bufTop = %i\n", bufTop));

  // Set outputs...
  ir = insnBuf[0];
  ir_valid = valid;
  pc = adrBuf[0];
  npc = adrBuf[1];
  ppc = adrBufM1;
  jal_adr = adrBuf[2];
  npc_valid = (adrTop >= 2);

  // Handle Jumps...
  if (jump == 1) {
    //INFO ("IFU: Caught Jump");
    ASSERT (adrTop >= 1);
    if (bufTop > 1) bufTop = 1;
    adrBuf[1] = jump_adr;
    adrTop = 2;
  }

  // Determine next buffer state...
  if (valid) {
  
    // Consume a queue item...
    if (next == 1) {
      ASSERT (bufTop >= 1);
      adrBufM1 = adrBuf[0];
      for (n = 0; n < adrTop-1; n++) {
        insnBuf[n] = insnBuf[n+1];
        adrBuf[n] = adrBuf[n+1];
      }
      bufTop--;
      adrTop--;
    }
  }

  // Create next loadable adress...
  if (adrTop < MAX_IFU_BUF_SIZE) {
    adrBuf[adrTop] = adrBuf[adrTop-1] + 4;
    adrTop++;
  }
}


void MIfu::MainThread () {
  int n;

  // Reset...
  bufTop = 0;
  adrBuf[0] = 0x100;
  adrTop = 1;

  // - to EXU
  ppc = 0;

  // - to memory
  rp_rd = 0;

  // Main loop...
  while (1) {
    StepBuffer ();
    wait ();

    // Reload actions...
    if (adrTop > bufTop                 // new adress available?
        && bufTop < MAX_IFU_BUF_SIZE    // space available?
        && (bufTop < 2 || !IsJump (insnBuf[bufTop-2]))) {     // jump pending? (-> load delay slot insn, but nothing more)
      rp_adr = adrBuf[bufTop];
      //INFOF (("### Loading adr %x, bufTop = %i, adrTop = %i", adrBuf[bufTop], bufTop, adrTop));
      rp_rd = 1;
      while (rp_ack == 0) {
        StepBuffer ();
        wait ();
      }
      rp_rd = 0;
      insnBuf[bufTop] = rp_data;
      bufTop++;
    }
  }
}
