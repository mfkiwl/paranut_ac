/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This is the top-level component of the ParaNut.
    It contains the following sub-modules:
    - 1 memory unit (MEMU)
    for each CPU:
    - 1 instruction fetch unit (IFU)
    - 1 execution unit (EXU)
    - 1 load-store unit (LSU)

 *************************************************************************/


#ifndef _PARANUT_
#define _PARANUT_

#include <systemc.h>

#include "memu.h"
#include "ifu.h"
#include "lsu.h"
#include "exu.h"



SC_MODULE(MParanut) {
  // SC_HAS_PROCESS(paranut_wb);

  // Ports (WISHBONE master)...
  sc_in<bool>          clk_i;     // clock input
  sc_in<bool>          rst_i;     // reset

  sc_out<bool>         cyc_o;     // cycle valid output
  sc_out<bool>         stb_o;     // strobe output
  sc_out<bool>         we_o;      // indicates write transfer
  sc_out<sc_uint<4> >  sel_o;     // byte select outputs
  sc_in<bool>          ack_i;     // normal termination
  sc_in<bool>          err_i;     // termination w/ error (presently unsupported)
  sc_in<bool>          rty_i;     // termination w/ retry (presently unsupported)

  sc_out<TWord>        adr_o;     // address bus outputs
  sc_in<TWord>         dat_i;     // input data bus
  sc_out<TWord>        dat_o;     // output data bus

  // Constructor/Destructor...
  SC_CTOR(MParanut) {
    InitSubmodules ();
    InitInterconnectMethod ();
  }
  ~MParanut () { FreeSubmodules (); }

  // Functions...
  void Trace (sc_trace_file *tf, int levels = 1);
  void DisplayStatistics () { exu[0]->DisplayStatistics (); }

  bool IsHalted () { return exu[0]->IsHalted (); }

  // Processes...
  void InterconnectMethod ();

  // Submodules...
  MMemu *memu;
  MIfu *ifu[CPU_CORES];
  MExu *exu[CPU_CORES];
  MLsu *lsu[CPU_CORES];

protected:

  // Connecting signals...

  //   MEMU: read ports (rp), write ports (wp)...
  sc_signal<bool> rp_rd[2*CPU_CORES], rp_direct[2*CPU_CORES];
  sc_signal<sc_uint<4> > rp_bsel[2*CPU_CORES];
  sc_signal<bool> rp_ack[2*CPU_CORES];
  sc_signal<TWord> rp_adr[2*CPU_CORES];
  sc_signal<TWord> rp_data[2*CPU_CORES];

  sc_signal<bool> wp_wr[CPU_CORES], wp_direct[CPU_CORES];
  sc_signal<sc_uint<4> > wp_bsel[CPU_CORES];
  sc_signal<bool> wp_ack[CPU_CORES];
  sc_signal<bool> wp_rlink_wcond[CPU_CORES];
  sc_signal<bool> wp_wcond_ok[CPU_CORES];
  sc_signal<bool> wp_writeback[CPU_CORES], wp_invalidate[CPU_CORES];
  sc_signal<TWord> wp_adr[CPU_CORES];
  sc_signal<TWord> wp_data[CPU_CORES];

  //   IFU ...
  sc_signal<bool> ifu_next[CPU_CORES], ifu_jump[CPU_CORES];
  sc_signal<TWord> ifu_jump_adr[CPU_CORES];   // jump adress
  sc_signal<bool> ifu_ir_valid[CPU_CORES], ifu_npc_valid[CPU_CORES];
  sc_signal<TWord> ifu_ir[CPU_CORES], ifu_ppc[CPU_CORES], ifu_pc[CPU_CORES], ifu_npc[CPU_CORES];   // expected to be registered (fast) outputs

  //   LSU ...
  sc_signal<bool> lsu_rd[CPU_CORES], lsu_wr[CPU_CORES], lsu_flush[CPU_CORES];
  sc_signal<bool> lsu_rlink_wcond[CPU_CORES], lsu_cache_writeback[CPU_CORES], lsu_cache_invalidate[CPU_CORES];
  sc_signal<bool> lsu_ack[CPU_CORES], lsu_align_err[CPU_CORES], lsu_wcond_ok[CPU_CORES];
  sc_signal<sc_uint<2> > lsu_width[CPU_CORES];  // "00" = word, "01" = byte, "10" = half word
  sc_signal<bool> lsu_exts[CPU_CORES];
  sc_signal<TWord> lsu_adr[CPU_CORES];
  sc_signal<TWord> lsu_rdata[CPU_CORES];
  sc_signal<TWord> lsu_wdata[CPU_CORES];

  //    others...
  sc_signal<bool> icache_enable, dcache_enable;

  // Methods...
  void InitSubmodules ();
  void FreeSubmodules ();
  void InitInterconnectMethod ();

  // Helpers...
};


#endif
