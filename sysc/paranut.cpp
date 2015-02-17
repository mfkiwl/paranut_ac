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


#include "paranut.h"





// **************** Trace *********************************


void MParanut::Trace (sc_trace_file *tf, int levels) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE (tf, clk_i);
  TRACE (tf, rst_i);

  TRACE (tf, cyc_o);
  TRACE (tf, stb_o);
  TRACE (tf, we_o);
  TRACE (tf, sel_o);
  TRACE (tf, ack_i);

  TRACE (tf, adr_o);
  TRACE (tf, dat_i);
  TRACE (tf, dat_o);

  // Connecting signals...
  //   MEMU ...
  TRACE_BUS (tf, rp_rd, 2*CPU_CORES);
  TRACE_BUS (tf, rp_direct, 2*CPU_CORES);
  TRACE_BUS (tf, rp_bsel, 2*CPU_CORES);
  TRACE_BUS (tf, rp_ack, 2*CPU_CORES);
  TRACE_BUS (tf, rp_adr, 2*CPU_CORES);
  TRACE_BUS (tf, rp_data, 2*CPU_CORES);
  TRACE_BUS (tf, wp_wr, CPU_CORES);
  TRACE_BUS (tf, wp_direct, CPU_CORES);
  TRACE_BUS (tf, wp_bsel, CPU_CORES);
  TRACE_BUS (tf, wp_ack, CPU_CORES);
  TRACE_BUS (tf, wp_rlink_wcond, CPU_CORES);
  TRACE_BUS (tf, wp_wcond_ok, CPU_CORES);
  TRACE_BUS (tf, wp_writeback, CPU_CORES);
  TRACE_BUS (tf, wp_invalidate, CPU_CORES);
  TRACE_BUS (tf, wp_adr, CPU_CORES);
  TRACE_BUS (tf, wp_data, CPU_CORES);
  //   IFU <-> EXU ...
  TRACE_BUS (tf, ifu_next, CPU_CORES);
  TRACE_BUS (tf, ifu_jump, CPU_CORES);
  TRACE_BUS (tf, ifu_jump_adr, CPU_CORES);
  TRACE_BUS (tf, ifu_ir_valid, CPU_CORES);
  TRACE_BUS (tf, ifu_npc_valid, CPU_CORES);
  TRACE_BUS (tf, ifu_ir, CPU_CORES);
  TRACE_BUS (tf, ifu_ppc, CPU_CORES);
  TRACE_BUS (tf, ifu_pc, CPU_CORES);
  TRACE_BUS (tf, ifu_npc, CPU_CORES);
  //   LSU <-> EXU ...
  TRACE_BUS (tf, lsu_rd, CPU_CORES);
  TRACE_BUS (tf, lsu_wr, CPU_CORES);
  TRACE_BUS (tf, lsu_flush, CPU_CORES);
  TRACE_BUS (tf, lsu_rlink_wcond, CPU_CORES);
  TRACE_BUS (tf, lsu_cache_writeback, CPU_CORES);
  TRACE_BUS (tf, lsu_cache_invalidate, CPU_CORES);
  TRACE_BUS (tf, lsu_ack, CPU_CORES);
  TRACE_BUS (tf, lsu_align_err, CPU_CORES);
  TRACE_BUS (tf, lsu_wcond_ok, CPU_CORES);
  TRACE_BUS (tf, lsu_width, CPU_CORES);
  TRACE_BUS (tf, lsu_exts, CPU_CORES);
  TRACE_BUS (tf, lsu_adr, CPU_CORES);
  TRACE_BUS (tf, lsu_rdata, CPU_CORES);
  TRACE_BUS (tf, lsu_wdata, CPU_CORES);
  //   other signals...
  TRACE (tf, icache_enable);
  TRACE (tf, dcache_enable);

  // Sub-Modules...
  if (levels > 1) {
    levels--;
    memu->Trace (tf, levels);
    for (int n = 0; n < CPU_CORES; n++) {
      ifu[n]->Trace (tf, levels);
      lsu[n]->Trace (tf, levels);
      exu[n]->Trace (tf, levels);
    }
  }
}





// **************** Submodules ****************************


void MParanut::InitSubmodules () {
  char name[80];
  int n;

  // MEMU...
  memu = new MMemu ("MemU");

  memu->clk (clk_i);
  memu->reset (rst_i);

  //   bus interface (Wishbone)...
  memu->wb_cyc_o (cyc_o);
  memu->wb_stb_o (stb_o);
  memu->wb_we_o (we_o);
  memu->wb_sel_o (sel_o);
  memu->wb_ack_i (ack_i);
  memu->wb_adr_o (adr_o);
  memu->wb_dat_i (dat_i);
  memu->wb_dat_o (dat_o);

  //    read ports...
  for (n = 0; n < 2 * CPU_CORES; n++) {
    memu->rp_rd[n] (rp_rd[n]);
    memu->rp_direct[n] (rp_direct[n]);
    memu->rp_bsel[n] (rp_bsel[n]);
    memu->rp_ack[n] (rp_ack[n]);
    memu->rp_adr[n] (rp_adr[n]);
    memu->rp_data[n] (rp_data[n]);
  }

  //   write ports...
  for (n = 0; n < CPU_CORES; n++) {
    memu->wp_wr[n] (wp_wr[n]);
    memu->wp_direct[n] (wp_direct[n]);
    memu->wp_bsel[n] (wp_bsel[n]);
    memu->wp_ack[n] (wp_ack[n]);
    memu->wp_rlink_wcond[n] (wp_rlink_wcond[n]);
    memu->wp_wcond_ok[n] (wp_wcond_ok[n]);
    memu->wp_writeback[n] (wp_writeback[n]);
    memu->wp_invalidate[n] (wp_invalidate[n]);
    memu->wp_adr[n] (wp_adr[n]);
    memu->wp_data[n] (wp_data[n]);
  }

  // IFUs...
  for (n = 0; n < CPU_CORES; n++) {
    sprintf (name, "IFU%i", n);
    ifu[n] = new MIfu (name);

    ifu[n]->clk (clk_i);
    ifu[n]->reset (rst_i);
  
    //   to MEMU (read port)...
    ifu[n]->rp_rd (rp_rd[CPU_CORES+n]);
    ifu[n]->rp_ack (rp_ack[CPU_CORES+n]);
    ifu[n]->rp_adr (rp_adr[CPU_CORES+n]);
    ifu[n]->rp_data (rp_data[CPU_CORES+n]);
  
    //   to EXU ...
    ifu[n]->next (ifu_next[n]);
    ifu[n]->jump (ifu_jump[n]);
    ifu[n]->jump_adr (ifu_jump_adr[n]);
    ifu[n]->ir (ifu_ir[n]);
    ifu[n]->ppc (ifu_ppc[n]);
    ifu[n]->pc (ifu_pc[n]);
    ifu[n]->npc (ifu_npc[n]);
    ifu[n]->ir_valid (ifu_ir_valid[n]);
    ifu[n]->npc_valid (ifu_npc_valid[n]);
  }

  // LSUs...
  for (n = 0; n < CPU_CORES; n++) {
    sprintf (name, "LSU%i", n);
    lsu[n] = new MLsu (name);

    lsu[n]->clk (clk_i);
    lsu[n]->reset (rst_i);

    //   to EXU...
    lsu[n]->rd (lsu_rd[n]);
    lsu[n]->wr (lsu_wr[n]);
    lsu[n]->flush (lsu_flush[n]);
    lsu[n]->rlink_wcond (lsu_rlink_wcond[n]);
    lsu[n]->cache_writeback (lsu_cache_writeback[n]);
    lsu[n]->cache_invalidate (lsu_cache_invalidate[n]);
    lsu[n]->ack (lsu_ack[n]);
    lsu[n]->align_err (lsu_align_err[n]);
    lsu[n]->wcond_ok (lsu_wcond_ok[n]);
    lsu[n]->width (lsu_width[n]);
    lsu[n]->exts (lsu_exts[n]);
    lsu[n]->adr (lsu_adr[n]);
    lsu[n]->rdata (lsu_rdata[n]);
    lsu[n]->wdata (lsu_wdata[n]);
  
    //   to MEMU/read port...
    lsu[n]->rp_rd (rp_rd[n]);
    lsu[n]->rp_bsel (rp_bsel[n]);
    lsu[n]->rp_ack (rp_ack[n]);
    lsu[n]->rp_adr (rp_adr[n]);
    lsu[n]->rp_data (rp_data[n]);
  
    //   to MEMU/write port...
    lsu[n]->wp_wr (wp_wr[n]);
    lsu[n]->wp_bsel (wp_bsel[n]);
    lsu[n]->wp_ack (wp_ack[n]);
    lsu[n]->wp_rlink_wcond (wp_rlink_wcond[n]);
    lsu[n]->wp_wcond_ok (wp_wcond_ok[n]);
    lsu[n]->wp_writeback (wp_writeback[n]);
    lsu[n]->wp_invalidate (wp_invalidate[n]);
    lsu[n]->wp_adr (wp_adr[n]);
    lsu[n]->wp_data (wp_data[n]);
  }

  // EXUs...
  for (n = 0; n < CPU_CORES; n++) {
    sprintf (name, "EXU%i", n);
    if (n == 0)
      exu[n] = new MExu (name, true, 3);    // CePU
    else
      exu[n] = new MExu (name, false, 2);   // CoPUs

    exu[n]->clk (clk_i);
    exu[n]->reset (rst_i);
  
    //   to IFU ...
    exu[n]->ifu_next (ifu_next[n]);
    exu[n]->ifu_jump (ifu_jump[n]);
    exu[n]->ifu_jump_adr (ifu_jump_adr[n]);
    exu[n]->ifu_ir_valid (ifu_ir_valid[n]);
    exu[n]->ifu_npc_valid (ifu_npc_valid[n]);
    exu[n]->ifu_ir (ifu_ir[n]);
    exu[n]->ifu_ppc (ifu_ppc[n]);
    exu[n]->ifu_pc (ifu_pc[n]);
    exu[n]->ifu_npc (ifu_npc[n]);
  
    //   to Load/Store Unit (LSU)...
    exu[n]->lsu_rd (lsu_rd[n]);
    exu[n]->lsu_wr (lsu_wr[n]);
    exu[n]->lsu_flush (lsu_flush[n]);
    exu[n]->lsu_cache_invalidate (lsu_cache_invalidate[n]);
    exu[n]->lsu_cache_writeback (lsu_cache_writeback[n]);
    exu[n]->lsu_ack (lsu_ack[n]);
    exu[n]->lsu_width (lsu_width[n]);
    exu[n]->lsu_exts (lsu_exts[n]);
    exu[n]->lsu_adr (lsu_adr[n]);
    exu[n]->lsu_rdata (lsu_rdata[n]);
    exu[n]->lsu_wdata (lsu_wdata[n]);
  }
  //   Special CePU signals...
  exu[0]->icache_enable(icache_enable);
  exu[0]->dcache_enable(dcache_enable);
}


void MParanut::FreeSubmodules () {
  int n;

  delete memu;
  for (n = 0; n < CPU_CORES; n++) {
    delete ifu[n];
    delete lsu[n];
    delete exu[n];
  }
}





// **************** Interconnect method *******************


void MParanut::InitInterconnectMethod () {
  int n;

  SC_METHOD (InterconnectMethod);

  // MEMU port signals...
  for (n = 0; n < 2*CPU_CORES; n++)
    sensitive << rp_adr[n];
  for (n = 0; n < CPU_CORES; n++)
    sensitive << wp_adr[n];
}


void MParanut::InterconnectMethod () {
  int n;

  // Constant IFU-MEMU signals...
  for (n = 0; n < CPU_CORES; n++)
    rp_bsel[CPU_CORES+n] = 0xf;

  // 'direct' lines for read/write ports...
  for (n = 0; n < CPU_CORES; n++) {
    if (cfgDisableCache) {
      rp_direct[n] = 1;
      wp_direct[n] = 1;
      rp_direct[CPU_CORES+n] = 1;
    } else {
      rp_direct[n] = (dcache_enable == 0 || !AdrIsCached (rp_adr[n]));
      wp_direct[n] = (dcache_enable == 0 || !AdrIsCached (wp_adr[n]));
      rp_direct[CPU_CORES+n] = (icache_enable == 0 || !AdrIsCached (rp_adr[n]));
    }
  }
}
