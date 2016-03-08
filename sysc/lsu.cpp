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


#include "lsu.h"

#include "config.h"



void MLsu::Trace (sc_trace_file *tf, int level) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE (tf, clk);
  TRACE (tf, reset);
  //   to EXU...
  TRACE (tf, rd);
  TRACE (tf, wr);
  TRACE (tf, flush);
  TRACE (tf, rlink_wcond);
  TRACE (tf, cache_writeback);
  TRACE (tf, cache_invalidate);
  TRACE (tf, ack);
  TRACE (tf, align_err);
  TRACE (tf, wcond_ok);
  TRACE (tf, width);
  TRACE (tf, exts);
  TRACE (tf, adr);
  TRACE (tf, rdata);
  TRACE (tf, wdata);
  //   to MEMU/read port...
  TRACE (tf, rp_rd);
  TRACE (tf, rp_bsel);
  TRACE (tf, rp_ack);
  TRACE (tf, rp_adr);
  TRACE (tf, rp_data);
  //   to MEMU/write port...
  TRACE (tf, wp_wr);
  TRACE (tf, wp_bsel);
  TRACE (tf, wp_ack);
  TRACE (tf, wp_rlink_wcond);
  TRACE (tf, wp_wcond_ok);
  TRACE (tf, wp_writeback);
  TRACE (tf, wp_invalidate);
  TRACE (tf, wp_adr);
  TRACE (tf, wp_data);

  // Registers...
  TRACE_BUS (tf, wbuf_adr, MAX_WBUF_SIZE);
  TRACE_BUS (tf, wbuf_data, MAX_WBUF_SIZE);
  TRACE_BUS (tf, wbuf_valid, MAX_WBUF_SIZE);
  TRACE (tf, wbuf_dirty0);

  // Internal signals...
  TRACE (tf, sig_wbdata);
  TRACE (tf, sig_wbbsel);
  TRACE (tf, sig_wbuf_entry);
  TRACE (tf, sig_wbuf_remove);
  TRACE (tf, sig_wbuf_write);
}



int MLsu::FindWbufHit (TWord adr) {
  for (int n = 0; n < MAX_WBUF_SIZE; n++)
    if (wbuf_adr[n] == (adr & ~3) && wbuf_valid[n].read () != 0) return n;
  return -1;
}


int MLsu::FindEmptyWbufEntry () {
  for (int n = 0; n < MAX_WBUF_SIZE; n++)
    if (wbuf_valid[n].read () == 0) return n;
  return -1;
}


bool MLsu::IsFlushed () {
  for (int n = 0; n < MAX_WBUF_SIZE; n++)
    if (wbuf_valid[n].read () != 0) return false;
  return true;
}


void MLsu::OutputMethod () {
  TWord rdata_var, wbdata;
  sc_uint<4> bsel;
  int n, wbuf_hit, wbuf_new, wbuf_entry;
  bool wbuf_dont_change0_var;

  // Set defaults (don't cares are left open)...
  ack = align_err = 0;

  rp_rd = 0;
  rp_adr = adr & ~3;

  //wp_rlink_wcond = 0;	//does this overwrite? was it just set because connection was not established yet?
  wp_rlink_wcond = rlink_wcond;
  wp_writeback = 0;
  wp_invalidate = 0;

  // Examine wbuf...
  wbuf_hit = FindWbufHit (adr);
  wbuf_new = FindEmptyWbufEntry ();

  // Generate 'sig_wbdata', 'sig_wbbsel'; general alignment check...
  switch (width.read ()) {
    case 0:
      if (adr & 3 != 0) { align_err = 1; return; }
      bsel = 0xf;
      wbdata = wdata;
      break;
    case 1:
      bsel = 1 << (adr & 3);
      wbdata = wdata & 0xff;
      wbdata = wbdata | (wbdata << 8) | (wbdata << 16) | (wbdata << 24);
      break;
    case 2:
      if (adr & 1 != 0) { align_err = 1; return; }
      bsel = 3 << (adr & 3);
      wbdata = wdata & 0xffff;
      wbdata = wbdata | (wbdata << 16);
      break;
  }
  if (cache_writeback == 1 || cache_invalidate == 1) bsel = 0;
  sig_wbdata = wbdata;
  sig_wbbsel = bsel;

  // NOTE: The 'rdata' signal must not depend on 'rd', since 'rdata' must still be readable one cycle after de-asserting 'rd'

  // Read request: generate 'rdata', 'rp_bsel'...
  rdata_var = rp_data;  // default
  rp_bsel = bsel;
  if (wbuf_hit >= 0) {
    //INFO ("LSU: Serving (partially) from the write buffer");
    for (n = 0; n < 4; n++) if (wbuf_valid[wbuf_hit].read () [n]) {
      rdata_var = (rdata_var & ~(0xff000000 >> (8*n))) | (wbuf_data[wbuf_hit] & (0xff000000 >> (8*n)));
      //INFOF (("LSU:   byte #%i, rdata_var = 0x%08x", n, rdata_var));
    }
  }
  switch (width.read ()) {   // Format data word & generate 'rdata'...
    case 1:
      rdata_var = (rdata_var >> (8 * (~adr & 3))) & 0xff;
      if (exts == 1) rdata_var = (rdata_var ^ 0x80) - 0x80;
      break;
    case 2:
      rdata_var = (rdata_var >> (8 * (~adr & 2))) & 0xffff;
      if (exts == 1) rdata_var = (rdata_var ^ 0x8000) - 0x8000;
      break;
  }
  rdata = rdata_var;

  // Read request: generate 'rp_rd', 'ack'...
  if (rd == 1) {
    //INFOF (("LSU: read request, adr = %x, bsel = 0x%x, wbuf_hit = %i", adr.read (), (int) bsel, wbuf_hit));
    if (wbuf_hit >= 0 && (bsel & ~wbuf_valid[wbuf_hit].read ()) == 0x0) {
      // we can serve all bytes from the write buffer
      // INFO ("LSU: Serving all bytes from the write buffer");
      rp_rd = 0;   // no request to memory
      ack = 1;
    }
    else {
      // we either have a write buffer miss or cannot serve all bytes
      // => pass through ack from the MEMU...
      rp_rd = 1;   // pass request to memory
      ack = rp_ack;
    }
  }

  // INFOF (("LSU:   bsel = %x, W := wbuf_valid[wbuf_hit].read () = %x, ~W = %x, bsel & ~W = %x",
  //        (int) bsel, (int) wbuf_valid[wbuf_hit].read (), (int) ~wbuf_valid[wbuf_hit].read (), (int) (bsel & ~wbuf_valid[wbuf_hit].read ())));

  // Handle flush mode (generate 'ack')...
  if (flush && IsFlushed ())
    ack = 1;

  // Generate MEMU write port signals ...
  wcond_ok = wp_wcond_ok;
  wp_adr = wbuf_adr[0];
  wp_data = wbuf_data[0];
  wp_bsel = wbuf_valid[0];
  if (IsFlushed () && (cache_writeback == 1 || cache_invalidate == 1)) {
    wp_wr = 0;  // cannot write now
    wp_writeback = cache_writeback;
    wp_invalidate = cache_invalidate;
    ack = wp_ack;
  }
  else {
    wp_wr = wbuf_dirty0; // (wbuf_valid[0].read () != 0);
    wp_writeback = 0;
    wp_invalidate = 0;
  }

  // Determine place for (eventual) new wbuf entry...
  if (wr == 1) {
    wbuf_entry = FindWbufHit (adr);
    if (wbuf_entry < 0 || AdrIsSpecial(adr)) wbuf_entry = FindEmptyWbufEntry ();
    if (wbuf_entry < 0) wbuf_entry = MAX_WBUF_SIZE;
    // INFOF (("LSU receiving write operation: wbuf_entry = %i", wbuf_entry));
  }
  else
    wbuf_entry = -1;   // no need to store new entry

  // Handle cache control operations...
  if (cache_writeback == 1 || cache_invalidate == 1) {
    ASSERT (wr == 0 && rd == 0);
    wbuf_entry = IsFlushed () ? 0 : -1;
    // Cache control is only allowed if the write buffer is flushed.
    // If asserted, the adress and (not necessary) data are copied to the buffer
    // reusing the same logic as for writes.
    // The 'valid' fields remain zero, so that 'IsFlushed ()' will still report "true".
    // The output method is responsible for forwarding the ACK signal from the write port
    // to the EXU.
  }
  sig_wbuf_entry = wbuf_entry;

  wbuf_dont_change0_var = 0;
  // this prevents changes of the wbuf in 2 situations:
  // - For a read hit in wbuf slot #0:
  //     make sure the wbuf is not changed in this clock cycle so that the forwarded data is still present in the next cycle
  // - For a write hit in wbuf slot #0:
  //     don't write into slot 0 if it is already writing
  if (wbuf_dirty0 == 1 && ((rd == 1 and wbuf_hit == 0) || (wr == 1 && wbuf_entry == 0))) wbuf_dont_change0_var = 1;

  // Remove oldest entry if MEMU write / cache_writeback  / cache_invalidate was completed...
  sig_wbuf_remove = 0;
  if (wbuf_dont_change0_var == 0 && (wbuf_dirty0 == 0 || wp_ack == 1) && wbuf_entry != 0) {
    // we can safely remove the data...
    sig_wbuf_remove = 1;
    wbuf_entry--;  // adjust new entry index, it may now point to the last entry MAX_WBUF_SIZE-1 if buffer was previously full
  }
  sig_wbuf_entry_new = wbuf_entry;

  // Handle write request...
  sig_wbuf_write = 0;
  if (wbuf_entry >= 0 && wbuf_entry < MAX_WBUF_SIZE && (!(AdrIsSpecial (adr) && wbuf_entry != 0) && wbuf_dont_change0_var == 0)) {
    // we can write into the write buffer & the transition thread will do so
    sig_wbuf_write = 1;
    ack = 1;
  }
}


void MLsu::TransitionThread () {
  // generates all register contents: wbuf_adr, wbuf_data, wbuf_valid
  int n;
  TWord data;
  sc_uint<4> valid;

  // Reset...
  for (n = 0; n < MAX_WBUF_SIZE; n++)
    wbuf_valid[n] = 0;
  wbuf_dirty0 = 0;

  // Main loop...
  while (1) {
    wait (1);

    // Read old data if applicable...
    if (sig_wbuf_entry >= 0 && sig_wbuf_entry < MAX_WBUF_SIZE) {
        data = wbuf_data[sig_wbuf_entry].read ();
        valid = wbuf_valid[sig_wbuf_entry].read ();
    } else
        valid = 0;

    if (wp_ack == 1) wbuf_dirty0 = 0;
    if (sig_wbuf_remove == 1) {
      wbuf_dirty0 = (wbuf_valid[1].read () != 0);
      for (n = 0; n < MAX_WBUF_SIZE-1; n++) {
        wbuf_adr[n] = wbuf_adr[n+1];
        wbuf_data[n] = wbuf_data[n+1];
        wbuf_valid[n] = wbuf_valid[n+1];
      }
      wbuf_valid[MAX_WBUF_SIZE-1] = 0;
    }

    // Store new entry if applicable...
    if (sig_wbuf_write == 1) {
      wbuf_adr[sig_wbuf_entry_new] = adr.read () & ~3;
      //INFOF (("Old data = 0x%08x", data));
      for (n = 0; n < 4; n++) {
        if (sig_wbbsel.read () [n] == 1) {
          data = (data & ~(0xff000000 >> (8*n))) | (sig_wbdata.read() & (0xff000000 >> (8*n)));
        }
      }
      wbuf_data[sig_wbuf_entry_new] = data;
      wbuf_valid[sig_wbuf_entry_new] = valid | sig_wbbsel.read();
      if (sig_wbuf_entry_new == 0) wbuf_dirty0 = 1;
      //INFOF (("LSU storing data word 0x%08x to entry #%i, bsel = %i",
      //        data, sig_wbuf_entry_new, (int) (wbuf_valid[sig_wbuf_entry_new].read () | sig_wbbsel.read())));
    }
  }
}
