/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2012 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

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
  TRACE (tf, sig_wbuf_dont_remove);
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
  int n, wbuf_hit, wbuf_new;

  // Set defaults (don't cares are left open)...
  ack = align_err = 0;

  rp_rd = 0;
  rp_adr = adr & ~3;

  wp_rlink_wcond = 0;
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
  sig_wbuf_dont_remove = 0;
  if (rd == 1) {
    // INFOF (("LSU: read request, adr = %x, bsel = 0x%x, wbuf_hit = %i", adr.read (), (int) bsel, wbuf_hit));
    if (wbuf_hit >= 0 && (bsel & ~wbuf_valid[wbuf_hit].read ()) == 0x0) {
      // we can serve all bytes from the write buffer
      // INFO ("LSU: Serving all bytes from the write buffer");
      if (wbuf_hit == 0) sig_wbuf_dont_remove = 1;
        // make sure the wbuf is not changed in this clock cycle so that the forwarded data is still present in the next cycle
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

  // Handle write request...
  if (wr == 1 && (wbuf_hit >= 0 || wbuf_new >= 0) && (!AdrIsSpecial (adr) || IsFlushed ())) {
    ack = 1;   // we can write into the write buffer & the transition thread will do so
  }

  // Handle flush mode (generate 'ack')...
  if (flush && IsFlushed ())
    ack = 1;

  // Generate MEMU write port signals ...
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
}


void MLsu::TransitionThread () {
  // generates all register contents: wbuf_adr, wbuf_data, wbuf_valid
  int wbuf_entry, n;
  TWord data;
  sc_uint<4> valid;

  // Reset...
  for (n = 0; n < MAX_WBUF_SIZE; n++)
    wbuf_valid[n] = 0;
  wbuf_dirty0 = 0;

  // Main loop...
  while (1) {
    wait (1);

    // Determine place for (eventual) new wbuf entry...
    if (wr == 1) {
      wbuf_entry = FindWbufHit (adr);
      if (wbuf_entry < 0) wbuf_entry = FindEmptyWbufEntry ();
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

    // Read old data if applicable...
    if (wbuf_entry >= 0 && wbuf_entry < MAX_WBUF_SIZE) {
      data = wbuf_data[wbuf_entry].read ();
      valid = wbuf_valid[wbuf_entry].read ();
    } else
        valid = 0;

    // Remove oldest entry if MEMU write / cache_writeback  / cache_invalidate was completed...
    if (wp_ack == 1) wbuf_dirty0 = 0;
    if (sig_wbuf_dont_remove == 0 && (wbuf_dirty0 == 0 || wp_ack == 1) && wbuf_entry != 0) {
      // we can safely remove the data...
      wbuf_dirty0 = (wbuf_valid[1].read () != 0);
      for (n = 0; n < MAX_WBUF_SIZE-1; n++) {
        wbuf_adr[n] = wbuf_adr[n+1];
        wbuf_data[n] = wbuf_data[n+1];
        wbuf_valid[n] = wbuf_valid[n+1];
      }
      wbuf_valid[MAX_WBUF_SIZE-1] = 0;
      wbuf_entry--;  // adjust new entry index, it may now point to the last entry MAX_WBUF_SIZE-1 if buffer was previously full
    }
  
    // Store new entry if applicable...
    if (wbuf_entry >= 0 && wbuf_entry < MAX_WBUF_SIZE && (!AdrIsSpecial (adr) || IsFlushed ())) {
      wbuf_adr[wbuf_entry] = adr.read () & ~3;
      //INFOF (("Old data = 0x%08x", data));
      for (n = 0; n < 4; n++) {
        if (sig_wbbsel.read () [n] == 1) {
          data = (data & ~(0xff000000 >> (8*n))) | (sig_wbdata.read() & (0xff000000 >> (8*n)));
        }
      }
      wbuf_data[wbuf_entry] = data;
      wbuf_valid[wbuf_entry] = valid | sig_wbbsel.read();
      if (wbuf_entry == 0) wbuf_dirty0 = 1;
      //INFOF (("LSU storing data word 0x%08x to entry #%i, bsel = %i",
      //        data, wbuf_entry, (int) (wbuf_valid[wbuf_entry].read () | sig_wbbsel.read())));
    }
  }
}
