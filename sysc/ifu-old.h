#ifndef _IFU_
#define _IFU_

#include "base.h"

#include <systemc.h>

#define MAX_IFU_BUF_SIZE 8



SC_MODULE(MIfu) {
public:

  // Ports ...
  sc_in<bool> clk, reset;

  //   to MEMU (read port)...
  sc_out<bool> rp_rd;
  sc_in<bool> rp_ack;
  sc_out<TWord> rp_adr;
  sc_in<TWord> rp_data;

  //   to EXU ...
  sc_in<bool> next, jump;
    // (next, jump) = (1, 1) lets the (current + 2)'th instruction be the jump target.
    // The behavior of (next, jump) = (0, 1) is not defined.
    // Both flags are ignored, if 'ir_valid' is unset (to allow handshake-pipelining).
  sc_in<TWord> jump_adr;
  sc_out<TWord> ir, ppc, pc, npc, jal_adr;   // registered outputs
  sc_out<bool> ir_valid, npc_valid;

  // Constructor...
  SC_CTOR(MIfu) {
    SC_CTHREAD (MainThread, clk.pos ());
      reset_signal_is (reset, true);
  }

  // Functions...
  void Trace (sc_trace_file *tf, int levels = 1);

  // Processes...
  void MainThread ();

protected:
  TWord insnBuf[MAX_IFU_BUF_SIZE];
  TWord adrBuf[MAX_IFU_BUF_SIZE], adrBufM1;
  int bufTop, adrTop;   // 'bufTop': first buffer place with not-yet-known contents (insn)
                        // 'adrTop': first buffer place with not-yet-known adress

  void StepBuffer ();
};


#endif
