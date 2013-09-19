/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This is a SystemC model of the instruction fetch unit (IFU) of the
    ParaNut. The IFU interfaces with the MEMU and the EXU and is capable
    of instruction prefetching.

 *************************************************************************/


#ifndef _IFU_
#define _IFU_

#include "base.h"

#include <systemc.h>


#define IFU_BUF_SIZE 4


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
    // Logically, 'next' is performed before 'jump'. Hence, jump instructions may either sequentially first
    // assert 'next' and then 'jump' or both signals in the same cycle. The former way is required for JAL instructions
    // to get the right return adress, which is PC+8 (or NPC+4).
  sc_in<TWord> jump_adr;
  sc_out<TWord> ir, ppc, pc, npc;   // registered outputs
  sc_out<bool> ir_valid, npc_valid;

  // Constructor...
  SC_CTOR(MIfu) {
    //SC_CTHREAD (MainThread, clk.pos ());
    //  reset_signal_is (reset, true);
    SC_METHOD (OutputMethod);
      for (int n = 0; n < IFU_BUF_SIZE; n++) sensitive << insn_buf[n] << adr_buf[n];
      sensitive << insn_top << adr_top;
    SC_METHOD (TransitionMethod);
      sensitive << clk.pos ();
  }

  // Functions...
  void Trace (sc_trace_file *tf, int levels = 1);

  // Processes...
  //void MainThread ();
  void OutputMethod ();
  void TransitionMethod ();

protected:
  sc_signal<TWord> insn_buf[IFU_BUF_SIZE];
  sc_signal<TWord> adr_buf[IFU_BUF_SIZE];
  sc_signal<int> insn_top, adr_top;   // 'insn_top': first buffer place with not-yet-known contents (insn)
                                      // 'adr_top': first buffer place with not-yet-known adress
  sc_signal<bool> last_rp_ack;

  void StepBuffer ();
};


#endif
