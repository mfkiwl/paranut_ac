/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2015 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This is a SystemC model of the load & store unit (LSU) of the ParaNut.
    The LSU interfaces with the EXU and the MEMU (1 load & 1 store port).
    It contains a write buffer with forwarding capabilities to the
    respective read port.

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


#ifndef _LSU_
#define _LSU_

#include "base.h"

#include <systemc.h>


#define MAX_WBUF_SIZE 4


// TODO:
// - support uncached access (no write buffer) and LL/SC instructions


SC_MODULE(MLsu) {
public:

  // Ports ...
  sc_in<bool> clk, reset;

  //   to EXU...
  sc_in<bool> rd, wr, flush, cache_writeback, cache_invalidate;
  sc_in<bool> rlink_wcond;
  sc_out<bool> ack, align_err, wcond_ok;
  sc_in<sc_uint<2> > width;  // "00" = word, "01" = byte, "10" = half word
  sc_in<bool> exts;
  sc_in<TWord> adr;
  sc_out<TWord> rdata;    // Note: 'rdata' is delayed by one clock relative to 'ack' (see comment to the read port interface in 'memu.h')
  sc_in<TWord> wdata;

  //   to MEMU/read port...
  sc_out<bool> rp_rd;
  sc_out<sc_uint<4> > rp_bsel;
  sc_in<bool> rp_ack;
  sc_out<TWord> rp_adr;
  sc_in<TWord> rp_data;

  //   to MEMU/write port...
  sc_out<bool> wp_wr;
  sc_out<sc_uint<4> > wp_bsel;
  sc_in<bool> wp_ack;
  sc_out<bool> wp_rlink_wcond;
  sc_in<bool> wp_wcond_ok;
  sc_out<bool> wp_writeback, wp_invalidate;
  sc_out<TWord> wp_adr;
  sc_out<TWord> wp_data;

  // Constructor...
  SC_CTOR(MLsu) {
    SC_CTHREAD (TransitionThread, clk.pos ());
      reset_signal_is (reset, true);
    SC_METHOD (OutputMethod);
      sensitive << rd << wr << flush << cache_writeback << cache_invalidate << rlink_wcond;
      sensitive << width << exts << adr << wdata;
      sensitive << rp_ack << rp_data << wp_ack;
      sensitive << wbuf_dirty0;
      for (int n = 0; n < MAX_WBUF_SIZE; n++)
        sensitive << wbuf_adr[n] << wbuf_data[n] << wbuf_valid[n];
  }

  // Functions...
  void Trace (sc_trace_file *tf, int level = 1);

  // Processes...
  void OutputMethod ();
  void TransitionThread ();

protected:

  // Registers...
  sc_signal<TWord> wbuf_adr [MAX_WBUF_SIZE];   // only bits 31:2 are relevant!!
  sc_signal<TWord> wbuf_data [MAX_WBUF_SIZE];
  sc_signal<sc_uint<4> > wbuf_valid [MAX_WBUF_SIZE];
  sc_signal<bool> wbuf_dirty0;  // is '1' if entry 0 needs to be written back

  // Internal signals...
  sc_signal<TWord> sig_wbdata;
  sc_signal<sc_uint<4> > sig_wbbsel;
  sc_signal<int> sig_wbuf_entry, sig_wbuf_entry_new;
  sc_signal<bool> sig_wbuf_remove;
  sc_signal<bool> sig_wbuf_write;

  // Helper methods...
  int FindWbufHit (TWord adr);
  int FindEmptyWbufEntry ();
  bool IsFlushed ();
};


#endif
