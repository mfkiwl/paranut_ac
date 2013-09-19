/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

 *************************************************************************/


#include "memu.h"

#include "lfsr.h"





// ***** SCacheTag *****


bool SCacheTag::operator== (const SCacheTag& t) const {
  return tadr == t.tadr && valid == t.valid && dirty == t.dirty && way == t.way;
}


SCacheTag& SCacheTag::operator= (const SCacheTag& t) {
  tadr = t.tadr; valid = t.valid; dirty = t.dirty; way = t.way;
}


ostream& operator<< (ostream& os, const SCacheTag& t) {
  os << "valid=" << t.valid << " dirty=" << t.dirty << " tadr=" << t.tadr << " way=" << t.way << endl;
  return os;
}


void sc_trace (sc_trace_file *tf, const SCacheTag& t, const std::string& name) {
  sc_trace (tf, t.tadr, name + ".tadr");
  sc_trace (tf, t.valid, name + ".valid");
  sc_trace (tf, t.dirty, name + ".dirty");
  sc_trace (tf, t.way, name + ".way");
}





// **************** Helpers *********************



static inline TWord GetBankOfAdr (TWord adr)  { return (adr >> 2) & (CACHE_BANKS - 1); }
static inline TWord GetIndexOfAdr (TWord adr) { return (adr >> (CACHE_BANKS_LD + 2)) & (CACHE_SETS - 1); }
static inline TWord GetWayIndexOfAdr (TWord adr, TWord way) { return GetIndexOfAdr (adr) | (way << CACHE_SETS_LD); }
static inline TWord GetIndexOfWayIndex (TWord adr) { return adr & (CACHE_SETS-1); }
static inline TWord GetTagOfAdr (TWord adr)   { return adr >> (CACHE_SETS_LD + CACHE_BANKS_LD + 2); }
static inline TWord GetLineOfAdr (TWord adr)  { return adr >> (CACHE_BANKS_LD + 2); }

static inline TWord ComposeAdress (TWord tadr, TWord iadr, TWord bank, TWord byteNo = 0) {
  return (tadr << (CACHE_SETS_LD+CACHE_BANKS_LD+2)) | (iadr << (CACHE_BANKS_LD+2)) | (bank << 2) | byteNo;
}


static void RequestWait (sc_out<bool> *req, sc_in<bool> *gnt) {
  *req = 1;
  // wait (1, SC_NS); // (SC_ZERO_TIME);   // TBD: allow to wait for 0 cycles (arbiter may respond in the same cycle)
  //while (*gnt == 0) wait (gnt->value_changed_event ());
  while (*gnt == 0) wait ();
}


static inline void RequestRelease (sc_out<bool> *req) {
  *req = 0;
}





// **************** MCacheBank ******************


void MBankRam::MainThread () {
  while (1) {
    for (int n = 0; n < BR_PORTS; n++) if (wr[n] == 1) ram[wiadr[n]] = wdata[n];
    for (int n = 0; n < BR_PORTS; n++) if (rd[n] == 1) rdata[n] = ram[wiadr[n]];
    wait ();
  }
}





// **************** MTagRam ********************


/*
bool STagEntry::operator== (const STagEntry& t) const {
  for (int n = 0; n < CACHE_WAYS; n++)
    if (valid[n] != t.valid[n] || dirty[n] != t.dirty[n] || tadr[n] != t.tadr[n]) return false;
  if (use != t.use) return false;
  return true;
}


STagEntry& STagEntry::operator= (const STagEntry& t) {
  for (int n = 0; n < CACHE_WAYS; n++) {
    valid[n] = t.valid[n];
    dirty[n] = t.dirty[n];
    tadr[n] = t.tadr[n];
  }
  use = t.use;
}


ostream& operator<< (ostream& os, const STagEntry& t) {
  for (int n = 0; n < CACHE_WAYS; n++)
    os << "valid[" << n <<"]=" << t.valid[n] << " dirty[" << n <<"]=" << t.dirty[n] << " tadr[" << n <<"]=" << t.tadr[n] << " ";
  os << "use=" << t.use << endl;
  return os;
}


void sc_trace (sc_trace_file *tf, const STagEntry& t, const std::string& name) {
  for (int n = 0; n < CACHE_WAYS; n++) {
    sc_trace (tf, t.valid[n], name + ".valid[" + n + "]");
    sc_trace (tf, t.dirty[n], name + ".dirty[" + n + "]");
    sc_trace (tf, t.tadr[n], name + ".tadr[" + n + "]");
  }
  sc_trace (tf, t.use, name + ".use");
}
*/

void MTagRam::Trace (sc_trace_file *tf, int level) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE(tf, clk);
  TRACE(tf, reset);
  TRACE(tf, ready);

  TRACE_BUS(tf, rd, TR_PORTS);
  TRACE_BUS(tf, wr, TR_PORTS);

  TRACE_BUS(tf, adr, TR_PORTS);   // complete adress (lower CACHE_BANKS_LD + 2 bits can be omitted)
  TRACE_BUS(tf, tag_in, TR_PORTS);
  TRACE_BUS(tf, tag_out, TR_PORTS);

  // Registers...
  TRACE_BUS(tf, use_reg, TR_PORTS)
  TRACE_BUS(tf, use_iadr_reg, TR_PORTS);
  TRACE_BUS(tf, use_wr_reg, TR_PORTS);
  TRACE(tf, counter);
}


static TWord GetNewUse (TWord oldUse, int way) {
  TWord newUse;
  int n;

  if (CACHE_WAYS == 1) newUse = 0;   // not really used
  else if (CACHE_WAYS == 2) newUse = 1 - way;
  else if (CACHE_WAYS == 4) {
    // The 'use' word is organized as follows:
    // - bits 1:0 represent the least recently used way (prio #0)
    // - bits 3:2 represent way with prio #1
    // - bits 5:4 represent way with prio #2 (future improvement: only use one bit for this)
    // - the most recently used way is not stored (can be derived)
    newUse = oldUse;

    // Set missing (most recently used) way to bits 7:6;
    // the XOR of all numbers from 00..11 is 00. Hence XOR'ing 3 different 2-bit numbers results in the missing one.
    newUse |= (((newUse >> 4) ^ (newUse >> 2) ^ newUse) & 3) << 6;

    // Search for the current way in the string and remove it if found...
    for (n = 0; n < 6; n += 2) if (((newUse >> n) & 3) == way)
      newUse = (newUse & ((1 << n)-1)) | ((newUse & ~((4 << n)-1)) >> 2);

    // Remove the uppermost bits...
    newUse &= 0x3f;
  }
  else ASSERTM(false, "Only 1-, 2-, or 4-way associative caches are supported with LRU replacement");

  return newUse;
}


void MTagRam::MainThread () {
  SCacheTag tag;
  STagEntry entry;
  TWord new_use;
  bool any_req;
  int way, p, n, k;

  // Reset...
  ready = 0;
  if (CACHE_REPLACE_LRU == 0)
    counter = 0xff;
  else
    for (n = 0; n < TR_PORTS; n++) use_wr_reg[n] = 0;

  for (n = 0; n < CACHE_SETS; n++) {
    for (k = 0; k < CACHE_WAYS; k++) {
      ram[n].valid[k] = 0;
      ram[n].dirty[k] = 0;
    }
    if (CACHE_REPLACE_LRU == 1)
      ram[n].use = CACHE_WAYS != 4 ? 0 : 0x24; // 4-way: 0x24 = 10.01.00b (see coding below)
  }

  // wait (CACHE_SETS);
  wait ();   // FPGAs can do the initialisation during personalisation
  ready = 1;

  // Main loop...
  while (true) {

    // Step random counter...
    if (CACHE_REPLACE_LRU == 0)
      counter = GetNextLfsrState (counter.read (), 8, GetPrimePoly (8, 0));  // (counter + 1) & 0xff;

    // Read access...
    for (p = 0; p < TR_PORTS; p++) if (rd[p] == 1) {
      entry = ram[GetIndexOfAdr(adr[p])];
      way = -1;  // no hit
      for (n = 0; n < CACHE_WAYS; n++)
        if (entry.valid[n] && entry.tadr[n] == GetTagOfAdr (adr[p])) {
          ASSERTF (way < 0, ("same data stored in two ways"));
          way = n;
        }
      if (way >= 0) {   // we had a hit...
        tag.valid = 1;
        if (CACHE_REPLACE_LRU == 1) {
          new_use = GetNewUse (entry.use, way);
          //INFOF (("    port #%i cache hit for adress %x (iadr=%x, tadr=%x): way = %i, use = %x, new_use = %x", p, adr[p].read (), GetIndexOfAdr(adr[p].read ()), GetTagOfAdr(adr[p].read ()), way, entry.use, new_use));
          if (new_use != entry.use) {
            entry.use = new_use;
            use_iadr_reg[p] = GetIndexOfAdr(adr[p]);
            use_reg[p] = new_use;
            use_wr_reg[p] = 1;
          }
          else
            use_wr_reg[p] = 0;
        }  // CACHE_REPLACE_LRU == 1
      }
      else {            // we had a miss...
        tag.valid = 0;
        if (CACHE_REPLACE_LRU == 0)
          way = counter & (CACHE_WAYS - 1);  // random replacement
        else {
          way = entry.use & (CACHE_WAYS - 1);
          //INFOF (("    port #%i cache miss for adress %x (iadr=%x): way = %i", p, adr[p].read (), GetIndexOfAdr(adr[p].read ()), way));
        }
      }
      tag.dirty = entry.dirty[way];
      tag.tadr = entry.tadr[way];
      tag.way = (TWord) way;

      tag_out[p] = tag;
    }

    // Writing ...
    p = -1;
    for (n = 0; n < TR_PORTS; n++) if (wr[n] == 1) {
      ASSERTF (p == -1, ("multiple tag write signals asserted"));
      p = n;
    }
    if (p >= 0) {
      // Handle a write request...
      entry = ram[GetIndexOfAdr(adr[p])];
      tag = tag_in[p].read ();
      way = tag.way;
      entry.valid[way] = tag.valid;
      entry.dirty[way] = tag.dirty;
      entry.tadr[way] = tag.tadr;
      entry.use = GetNewUse (entry.use, way);
      ram[GetIndexOfAdr(adr[p])] = entry;

      wait ();  // This writing requires 2 clock cycles, since only a part of the memory line is changed
    }
    else if (CACHE_REPLACE_LRU == 1) {
      // No external write request: Write back some use info if pending...
      for (n = 0; n < TR_PORTS && p < 0; n++) if (use_wr_reg[n] == 1) p = n;
      if (p >= 0) {
        // INFOF (("    writing back tag use: iadr = %x, port #%i", use_iadr_reg[p].read (), p));
        entry = ram[use_iadr_reg[p]];  // 'entry' must have been saved in a register during the past read cycle!
        entry.use = use_reg[p];

        ram[use_iadr_reg[p]] = entry;
        use_wr_reg[p] = 0;
      }
    }

    wait ();    // End of clock cycle
  }
}





// **************** MBusIf **********************


void MBusIf::Trace (sc_trace_file *tf, int level) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE(tf, clk);
  TRACE(tf, reset);

  //   Bus interface (Wishbone)...
  TRACE(tf, wb_cyc_o);
  TRACE(tf, wb_stb_o);
  TRACE(tf, wb_we_o);
  TRACE(tf, wb_sel_o);
  TRACE(tf, wb_ack_i);
  TRACE(tf, wb_adr_o);
  TRACE(tf, wb_dat_i);
  TRACE(tf, wb_dat_o);

  //   Control inputs/outputs...
  TRACE(tf, busif_op);
  TRACE(tf, busif_nolinelock);
  TRACE(tf, busif_bsel);
  TRACE(tf, busif_busy);

  //   Control lines to Tag & Cache banks...
  TRACE(tf, tag_rd);
  TRACE(tf, tag_wr);
  TRACE_BUS(tf, bank_rd, CACHE_BANKS);
  TRACE_BUS(tf, bank_wr, CACHE_BANKS);

  //   Adress & data busses...
  TRACE(tf, adr_in);
  TRACE(tf, adr_out);
  TRACE_BUS(tf, data_in, CACHE_BANKS);
  TRACE_BUS(tf, data_out, CACHE_BANKS);
  TRACE_BUS(tf, data_out_valid, CACHE_BANKS);
  TRACE(tf, tag_in);
  TRACE(tf, tag_out);

  //   Request & grant lines...
  TRACE(tf, req_linelock);
  TRACE(tf, req_tagw);
  TRACE(tf, req_tagr);
  TRACE_BUS(tf, req_bank, CACHE_BANKS);
  TRACE(tf, gnt_linelock);
  TRACE(tf, gnt_tagw);
  TRACE(tf, gnt_tagr);
  TRACE_BUS(tf, gnt_bank, CACHE_BANKS);

  // Registers...
  TRACE(tf, op_reg);
  TRACE(tf, nolinelock_reg);
  TRACE(tf, bsel_reg);
  TRACE(tf, adr_reg);
  TRACE_BUS(tf, idata_reg, CACHE_BANKS);
  TRACE_BUS(tf, odata_reg, CACHE_BANKS);
  TRACE_BUS(tf, idata_valid_reg, CACHE_BANKS);
  TRACE(tf, tag_reg);
}


void MBusIf::OutputMethod () {
  int n;

  adr_out = adr_reg;
  for (n = 0; n < CACHE_BANKS; n++) data_out[n] = idata_reg[n];
  for (n = 0; n < CACHE_BANKS; n++) data_out_valid[n] = idata_valid_reg[n];
}


void MBusIf::AcceptNewOp () {
  int n;

  if (busif_op.read () != bioNothing) {
    busif_busy = 1;

    // Latch all inputs since the BUSIF requester may release the request after one clock cycle...
    op_reg = busif_op;
    nolinelock_reg = busif_nolinelock;
    bsel_reg = busif_bsel;
    adr_reg = adr_in;
    for (n = 0; n < CACHE_BANKS; n++) odata_reg[n] = data_in[n];    // only needed for direct writes
  }
}


void MBusIf::MainThread () {
  sc_uint<CACHE_BANKS> banksLeft;
  SCacheTag tag;
  TWord adrBase, adrOfs, victimData[CACHE_BANKS];
  bool write_victim;
  int n;

  // Reset...
  for (n = 0; n < CACHE_BANKS; n++) idata_valid_reg[n] = 0;
  op_reg = bioNothing;
  busif_busy = 0;
  wait ();

  // Main loop...
  while (1) {

    // Defaults for outputs...
    wb_cyc_o = 0;
    wb_stb_o = 0;
    wb_we_o = 0;
    tag_rd = 0;
    tag_wr = 0;
    req_tagw = 0;
    req_linelock = 0;
    for (n = 0; n < CACHE_BANKS; n++) {
      req_bank[n] = 0;
      bank_rd[n] = 0;
      bank_wr[n] = 0;
    }
    wb_sel_o = 0xf;  // always select 32 bit unless direct access is requested

    // Wait for new request...
    while (op_reg.read () == bioNothing) {
      AcceptNewOp ();
      wait ();
    }

    // Direct read...
    if (op_reg.read () == bioDirectRead) {

      // Perform WB read cycle...
      wb_adr_o = adr_reg.read ();
      wb_sel_o = bsel_reg;
      wb_cyc_o = 1;
      wb_stb_o = 1;
      while (wb_ack_i == 0) wait ();
      idata_reg[GetBankOfAdr (adr_reg)] = wb_dat_i.read ();
      idata_valid_reg[GetBankOfAdr (adr_reg)] = 1;
      wb_cyc_o = 0;
      wb_stb_o = 0;

      wait ();

      busif_busy = 0;
      op_reg = bioNothing;

      idata_valid_reg[GetBankOfAdr (adr_reg)] = 0;  // Reset valid signal to avoid wrong BUSIF hits
      // Note: 'idata_reg' must still be valid in the first cycle of 'idata_valid_out = 0' due to pipelining in the read ports

      wait ();
    }
    else if (op_reg.read () == bioDirectWrite) {

      // Perform WB write cycle...
      wb_adr_o = adr_reg.read ();
      wb_dat_o = odata_reg[GetBankOfAdr(adr_reg)].read ();
      wb_sel_o = bsel_reg;
      wb_we_o = 1;
      wb_cyc_o = 1;
      wb_stb_o = 1;
      while (wb_ack_i == 0) wait ();
      wb_cyc_o = 0;
      wb_stb_o = 0;

      busif_busy = 0;
      op_reg = bioNothing;

      wait ();
    }
    else {          // All cache-related operations...

      // Helper variables...
      adrBase = adr_reg & ~(4 * CACHE_BANKS - 1);
      adrOfs = (adr_reg & ~3) - adrBase;
      write_victim = 0;

      // Lock cache line...
      if (!nolinelock_reg) RequestWait (&req_linelock, &gnt_linelock);
        // lock this cache line first as a protection against inconsistencies between
        // the BUSIF data register and the cache contents;
        // During reading, data may be forwarded to the read ports from the BUSIF according to
        // 'idata_valid', even if the lock is held

      // Read tag...
      tag_rd = 1;
      RequestWait (&req_tagr, &gnt_tagr);
      wait ();
      tag_reg = tag_in;
      tag_rd = 0;
      RequestRelease (&req_tagr);
      wait ();  // now the tag is in 'tag_reg'

      // Read (new) bus data into 'idata' register...
      //   ... allowing to serve a read request as early as possible
      if (op_reg.read () == bioReplace) {
        wb_cyc_o = 1;
        for (n = 0; n < CACHE_BANKS; n++) {
          wb_adr_o = adrBase | adrOfs;
          wb_stb_o = 1;
          do { wait (); } while (wb_ack_i == 0);
          idata_reg[adrOfs >> 2] = wb_dat_i.read ();
          idata_valid_reg[adrOfs >> 2] = 1;
          adr_reg = adrBase | adrOfs;
          wb_stb_o = 0;
          adrOfs = (adrOfs + 4) & (4 * CACHE_BANKS - 1);
        }
        wb_cyc_o = 0;
      }

      // Check if write back will be necessary & read cache line to 'odata_reg'...
      if (tag_reg.read().dirty &&
          (op_reg.read () == bioWriteback || op_reg.read () == bioFlush || op_reg.read () == bioReplace)) {

        tag_out = tag_reg;    // needed to put the 'way' to the outputs...

        // Read (old) cache bank into 'odata' register (with maximum parallelism)...
        banksLeft = (1 << CACHE_BANKS) - 1;
        while (banksLeft > 0) {
          for (n = 0; n < CACHE_BANKS; n++) {
            req_bank[n] = banksLeft[n];
            bank_rd[n] = banksLeft[n];
          }
          for (n = 0; n < CACHE_BANKS; n++) if (gnt_bank[n] == 1)  // verify if correct read is possible (check of 'gnt_bank' must be BEFORE writing to 'odata_reg')
            banksLeft[n] = 0;    // can
          wait ();
          for (n = 0; n < CACHE_BANKS; n++) if (gnt_bank[n] == 1)
            odata_reg[n] = data_in[n];   // data comes from cache bank
        }
        for (n = 0; n < CACHE_BANKS; n++) {
          req_bank[n] = 0;
          bank_rd[n] = 0;
        }

        write_victim = 1;
      }

      // Write new data to cache line...
      if (op_reg.read () == bioReplace) {

        // Write invalid tag (to make sure that concurrent readers do not receive invalid data)...
        tag = tag_reg;
        tag.valid = 0;

        RequestWait (&req_tagw, &gnt_tagw);
        tag_out = tag;
        tag_wr = 1;
        wait ();
        wait ();
        tag_wr = 0;
        RequestRelease (&req_tagw);

        // Write data to cache banks; operate in parallel as much as possible
        banksLeft = (1 << CACHE_BANKS) - 1;
        while (banksLeft > 0) {
          for (n = 0; n < CACHE_BANKS; n++) {
            req_bank[n] = banksLeft[n];
            bank_wr[n] = banksLeft[n];
          }
          wait ();
          for (n = 0; n < CACHE_BANKS; n++) if (gnt_bank[n])
            banksLeft[n] = 0;
        }
        for (n = 0; n < CACHE_BANKS; n++) {
          req_bank[n] = 0;
          bank_wr[n] = 0;
        }
      }

      // Write new tag...
      tag = tag_reg;
      tag.tadr = GetTagOfAdr (adr_reg);
      if (op_reg.read () == bioFlush || op_reg.read () == bioInvalidate) tag.valid = 0;
      if (op_reg.read () == bioReplace) tag.valid = 1;
      tag.dirty = 0;
      tag_out = tag;

      RequestWait (&req_tagw, &gnt_tagw);
      tag_wr = 1;
      wait ();
      wait ();
      tag_wr = 0;
      RequestRelease (&req_tagw);

      // Write back victim data to bus...
      if (write_victim) {
        wait ();   // ... for 'odata_reg' to take over new data
        wb_cyc_o = 1;
        wb_we_o = 1;
        for (n = 0; n < CACHE_BANKS; n++) {
          wb_adr_o = ComposeAdress (tag_reg.read ().tadr, GetIndexOfAdr (adr_reg), n, 0);
          wb_dat_o = odata_reg[n].read ();
          wb_stb_o = 1;
          do { wait (); } while (wb_ack_i == 0);
          wb_stb_o = 0;
        }
        wb_cyc_o = 0;
        wb_we_o = 0;
      }
  
      // Acknowledge...
      for (n = 0; n < CACHE_BANKS; n++) idata_valid_reg[n] = 0;   // disable data forwarding, as from now on this line may be modified in the cache
      busif_busy = 0;
      op_reg = bioNothing;
      wait ();

      // Unlock cache line...
      if (nolinelock_reg == 0) RequestRelease (&req_linelock);
        // Note: 'idata_reg' must still be valid in the first cycle of 'idata_valid_out == 0' due to pipelining in the read ports;
        //       The linelock must also be kept up sufficiently long to avoid inconsistencies.
    }
  }
}





// **************** MReadPort *******************


void MReadPort::Trace (sc_trace_file *tf, int level) {
 if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE(tf, clk);
  TRACE(tf, reset);

  TRACE(tf, port_rd);
  TRACE(tf, port_direct);
  TRACE(tf, port_ack);
  TRACE(tf, port_adr);
  TRACE(tf, port_data);

  //   Towards BUSIF...
  TRACE(tf, busif_adr);
  TRACE(tf, busif_data);
  TRACE_BUS(tf, busif_data_valid, CACHE_BANKS);
  TRACE(tf, busif_op);
  TRACE(tf, busif_busy);

  //   Towards cache...
  //   - Adress information for tag/banks are routed around this module from 'port_adr'.
  TRACE(tf, tag_rd);
  TRACE(tf, bank_rd);
  TRACE(tf, bank_data_in);
  TRACE(tf, bank_sel);
  TRACE(tf, tag_in);
  TRACE(tf, way_out);

  //   Request & grant lines...
  TRACE(tf, req_tagr);
  TRACE_BUS(tf, req_bank, CACHE_BANKS);
  TRACE(tf, req_busif);
  TRACE(tf, gnt_tagr);
  TRACE_BUS(tf, gnt_bank, CACHE_BANKS);
  TRACE(tf, gnt_busif);

  // Registers...
  TRACE(tf, state_trace);
  TRACE(tf, bank_sel_reg);

  // Internal signals...
  TRACE(tf, busif_hit);
}


void MReadPort::HitMethod () {
  busif_hit = busif_data_valid[GetBankOfAdr(port_adr)].read () && port_adr.read () == busif_adr.read ();
}


void MReadPort::TransitionMethod () {
  state_reg = next_state;
  state_trace = (int) next_state.read ();

  bank_sel_reg = next_bank_sel;
}


void MReadPort::MainMethod () {
  TWord index, bank;
  bool tagr_req_rd, bank_req_rd;   // 'req' and 'rd' signals can be identical
  bool tagr_gnt, bank_gnt;
  int n;

  // Defaults for outputs...
  port_ack = 0;
  req_busif = 0;
  for (n = 0; n < CACHE_BANKS; n++) req_bank[n] = 0;
  busif_op = bioNothing;

  bank_sel = bank_sel_reg;
  way_out = tag_in.read ().way;  // TBD: need a register for this?

  next_state = state_reg;
  next_bank_sel = bank_sel_reg;

  // Helper variable...
  index = GetIndexOfAdr (port_adr);
  bank = GetBankOfAdr (port_adr);
  tagr_req_rd = bank_req_rd = 0;
  tagr_gnt = gnt_tagr;
  bank_gnt = gnt_bank[bank];

  if (reset == 1)
    next_state = s_rp_init;
  else switch (state_reg.read ()) {

    case s_rp_init: // 0
      // Initial state: On new request, initiate all actions for the first cycle
      if (port_rd == 1) {
        if (port_direct == 1) {
          // uncached memory access...
          busif_op = bioDirectRead;
          req_busif = 1;
          if (gnt_busif == 1) next_state = s_rp_direct_wait_busif;
        }
        else {
          // cached memory access...
          if (busif_hit == 1) {
            port_data = busif_data;
            port_ack = 1;
          }
          else {
            tagr_req_rd = 1;
            if (tagr_gnt == 1) next_state = s_rp_read_tag;
          }
        }
      }
      break;

    case s_rp_direct_wait_busif: // 1
      // Direct access: Wait for response from the BusIf
      busif_op = bioDirectRead;
      req_busif = 1;
      port_data = busif_data;
      if (busif_hit == 1) {
        port_ack = 1;
        next_state = s_rp_init;
      }
      break;

    case s_rp_read_tag: // 3
      // capture the tag (which was granted last state)
      tagr_req_rd = 1;
      if (tag_in.read ().valid == 1) {
        // Cache hit...
        bank_req_rd = 1;
        if (bank_gnt == 1) {
          next_bank_sel = bank;
          port_ack = 1;
          next_state = s_rp_read_bank;
        }
      }
      else next_state = s_rp_miss_wait_busif;
      break;

    case s_rp_read_bank: // 4
      // read the bank & complete ...
      tagr_req_rd = 1;

      port_data = bank_data_in;
      // port_ack = 1;
      next_state = s_rp_init;

      // On new request, initiate all actions for the first cycle
      if (port_rd == 1) {
        if (port_direct == 1) {
          // uncached memory access...
          busif_op = bioDirectRead;
          req_busif = 1;
          if (gnt_busif == 1) next_state = s_rp_direct_wait_busif;
        }
        else {
          // cached memory access...
          if (busif_hit == 1) {
            port_data = busif_data;
            port_ack = 1;
          }
          else {
            tagr_req_rd = 1;
            if (tagr_gnt == 1) next_state = s_rp_read_tag;
          }
        }
      }
      break;

    case s_rp_miss_wait_busif: // 5
      // Cache miss detected: Wait until we get the BusIf and the BusIf becomes idle and catch an
      // incidental BusIf hit if it happens.
      req_busif = 1;
      if (busif_hit == 1) {
        port_data = busif_data;
        port_ack = 1;
        next_state = s_rp_init;
      }
      else if (gnt_busif == 1 && busif_busy == 0)
        next_state = s_rp_miss_request_tag;
      break;

    case s_rp_miss_request_tag: // 6
      // Request the tag again to check for a cache hit. The BusIf might already have replaced the
      // cache line during 's_rp_miss_wait_busif' on the request of some other port, and that data may have
      // even been modified by a write port! Hence, replacing that cache line again would lead to wrong data.
      req_busif = 1;
      tagr_req_rd = 1;
      if (tagr_gnt == 1)
        next_state = s_rp_miss_read_tag;
      break;

    case s_rp_miss_read_tag: // 7
      // read the tag & check for a cache hit
      req_busif = 1;
      tagr_req_rd = 1;
      if (tag_in.read ().valid == 1) {
        bank_req_rd = 1;
        if (bank_gnt == 1) next_state = s_rp_read_bank;
      }
      else
        next_state = s_rp_miss_replace;
      break;

    case s_rp_miss_replace: // 8
      // Run the replacement and wait for the BusIf hit which MUST come some time
      req_busif = 1;
      busif_op = bioReplace;
      if (busif_hit == 1) {
        port_data = busif_data;
        port_ack = 1;
        next_state = s_rp_init;
      }
      break;

  } // switch (state_reg)

  // Set derived outputs...
  req_tagr = tagr_req_rd;
  tag_rd = tagr_req_rd;
  req_bank[bank] = bank_req_rd;
  bank_rd = bank_req_rd;
}





// **************** MWritePort *******************


void MWritePort::Trace (sc_trace_file *tf, int level) {
 if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE(tf, clk);
  TRACE(tf, reset);

  //   Towards (CPU) port...
  //   - All input ports must be held until 'port_ack' is asserted.
  TRACE(tf, port_wr);
  TRACE(tf, port_direct);
  TRACE(tf, port_bsel);
  TRACE(tf, port_ack);

  TRACE(tf, port_rlink_wcond);
  TRACE(tf, port_wcond_ok);

  TRACE(tf, port_writeback);
  TRACE(tf, port_invalidate);

  TRACE(tf, port_adr);
  TRACE(tf, port_data);

  //   Towards BUSIF...
  //   - There is no direct transfer except for uncached memory access.
  TRACE(tf, busif_adr);
  TRACE(tf, busif_op);
  TRACE(tf, busif_nolinelock);
  TRACE(tf, busif_busy);

  //   Towards cache...
  //   - Adress information for tag/banks must be routed from 'port_adr'.
  TRACE(tf, tag_rd);
  TRACE(tf, tag_wr);
  TRACE(tf, bank_rd);
  TRACE(tf, bank_wr);
  TRACE(tf, bank_data_in);
  TRACE(tf, bank_data_out);
  TRACE(tf, tag_in);
  TRACE(tf, tag_out);

  //   Request & grant lines...
  TRACE(tf, req_linelock);
  TRACE(tf, req_tagr);
  TRACE(tf, req_tagw);
  TRACE_BUS(tf, req_bank, CACHE_BANKS);
  TRACE(tf, req_busif);
  TRACE(tf, gnt_linelock);
  TRACE(tf, gnt_tagr);
  TRACE(tf, gnt_tagw);
  TRACE_BUS(tf, gnt_bank, CACHE_BANKS);
  TRACE(tf, gnt_busif);

  //   Towards snoop unit (arbiter)...
  TRACE(tf, snoop_adr);
  TRACE(tf, snoop_stb);

  // Internal register & signals...
  TRACE(tf, state_trace);
  TRACE(tf, tag_reg);
  TRACE(tf, data_reg);
  TRACE(tf, link_adr_reg);
  TRACE(tf, link_valid_reg);

  TRACE(tf, next_tag_reg);
  TRACE(tf, next_data_reg);
  TRACE(tf, next_link_adr_reg);
  TRACE(tf, next_link_valid_reg);
}


void MWritePort::TransitionMethod () {
  state_reg = next_state;
  state_trace = (int) next_state.read ();

  tag_reg = next_tag_reg;
  data_reg = next_data_reg;

  link_adr_reg = next_link_adr_reg;
  link_valid_reg = next_link_valid_reg;
}


static TWord CombineData (sc_uint<4> bsel, TWord word0, TWord word1) {
  TWord ret;
  int n;

  ret = word1;
  if (bsel != 0xf) {  // full word skipped (just to improve simulation speed)
    for (n = 0; n < 4; n++) if (bsel [3-n] == 0) {
      ret &= ~(0xff << (8 * n));
      ret |= (word0 & (0xff << (8 * n)));
    }
  }
  return ret;
}


void MWritePort::MainMethod () {
  SCacheTag tag;
  TWord index, bank, data;
  bool tagr_req_rd, bank_req_rd;   // 'req' and 'rd' signals can be identical
  bool bank_gnt;

  int n;

  // To avoid over-length paths, 'gnt_*' inputs only influence the next state, but not the outputs of this module.
  // Besides this, this is a Mealy-type machine for performance reasons. (Do we need more restrictions?)

  // Defaults for outputs...
  port_ack = 0;
  port_wcond_ok = link_valid_reg;

  busif_op = bioNothing;
  busif_nolinelock = 1;

  tag_wr = 0;
  bank_wr = 0;
  tag_out = tag_reg;

  req_linelock = 0;
  req_tagr = 0;
  req_tagw = 0;
  for (n = 0; n < CACHE_BANKS; n++) req_bank[n] = 0;
  req_busif = 0;

  next_state = state_reg;
  next_tag_reg = tag_reg;
  next_data_reg = data_reg;

  // Helper variables...
  index = GetIndexOfAdr (port_adr);
  bank = GetBankOfAdr (port_adr);
  tagr_req_rd = bank_req_rd = 0;
  bank_gnt = gnt_bank[bank];

  // Update link registers...
  next_link_adr_reg = link_adr_reg;
  next_link_valid_reg = link_valid_reg;
  if (snoop_stb == 1) {
    if (snoop_adr == link_adr_reg)   // need to invalidate?
      next_link_valid_reg = 0;
  }

  // Main "switch"...
  if (reset == 1) {
    next_state = s_wp_init;
    next_link_valid_reg = 0;
  }
  else switch (state_reg.read ()) {

    case s_wp_init: // 0
      if (port_wr == 1) {
        if (port_direct == 1) {
          // Direct (uncached) memory access...
          req_busif = 1;
          busif_op = bioDirectWrite;
          if (gnt_busif == 1 && busif_busy == 0)
            next_state = s_wp_direct;
        }
        else {
          // Normal (cached) access...
          if (port_rlink_wcond == 1 && link_valid_reg == 0) {
            // This is a "store conditional" (SC), which has failed right away...
            // (a failure may still occur later, even if this condition has not yet been fulfilled here)
            port_ack = 1;
          }
          else {
            // Normal and (so far) successful SC cache accesses...
            req_linelock = 1;
            tagr_req_rd = 1;
            if (gnt_tagr == 1) {
              if (gnt_linelock == 1) next_state = s_wp_read_tag;
              else next_state = s_wp_request_linelock_only;
            }
          }
        }
      }
      else if (port_writeback == 1 || port_invalidate == 1) {
        // Special operation...
        req_busif = 1;
        req_linelock = 1;
        if (gnt_linelock == 1 && gnt_busif == 0) next_state = s_wp_special_request_busif_only;
        if (gnt_busif == 1 && busif_busy == 0) next_state = s_wp_special;
      }
      else if (port_rlink_wcond == 1) {
        // Link current adress (LL operation)...
        next_link_adr_reg = port_adr;
        next_link_valid_reg = 1;
      }
      break;

    // Additional state for direct memory access...

    case s_wp_direct: // 1
      // Issue "direct write" operation...
      req_busif = 1;
      busif_op = bioDirectWrite;
      if (busif_busy == 1) {
        // Now the BUSIF is busy and has captured the data -> can ack and complete
        port_ack = 1;
        next_state = s_wp_init;
      }
      break;

    // Additional states for normal access...

    case s_wp_request_linelock_only: // 2
      // We got a grant for 'tagr', but not the 'linelock'
      // => We must release everything except the 'linelock' to avoid a deadlock
      req_linelock = 1;
      if (gnt_linelock == 1) next_state = s_wp_init;
      break;

    case s_wp_read_tag: // 3
      // Capture the tag and request the bank...
      req_linelock = 1;
      if (port_bsel.read () < 0xf) bank_req_rd = 1;
      tag_out = tag_in;   // for bank reading to output the correct cache way
      next_tag_reg = tag_in;
      if (tag_in.read ().valid == 1) {
        // Cache hit...
        if (port_bsel.read () == 0xf) {
          if (tag_in.read ().dirty == 1) next_state = s_wp_write_bank;
          else next_state = s_wp_write_tag1_and_bank;
        }
        else if (bank_gnt == 1) next_state = s_wp_read_bank;
        else next_state = s_wp_have_tag_request_bank;
      }
      else next_state = s_wp_miss;
      break;

    case s_wp_have_tag_request_bank: // 4
      req_linelock = 1;
      bank_req_rd = 1;
      if (bank_gnt == 1) next_state = s_wp_read_bank;
      break;

    case s_wp_read_bank:  // 5
      // read old word (for part-word write only)...
      req_linelock = 1;
      bank_req_rd = 1;
      next_data_reg = bank_data_in;
      if (tag_reg.read ().dirty == 1) next_state = s_wp_write_bank;
      else next_state = s_wp_write_tag1_and_bank;
      break;

    case s_wp_write_tag1_and_bank: // 6
      req_linelock = 1;
      req_tagw = 1;
      tag = tag_reg; tag.dirty = 1; tag_out = tag;
      bank_req_rd = 1;
      bank_data_out = CombineData (port_bsel, data_reg, port_data);
      if (bank_gnt == 1) {
        bank_wr = 1;
        next_state = s_wp_write_tag1;
      }
      if (gnt_tagw == 1) {
        tag_wr = 1;
        next_state = s_wp_write_tag2_and_bank;
      }
      if (bank_gnt == 1 && gnt_tagw == 1) {
        next_state = s_wp_write_tag2;
      }
      break;

    case s_wp_write_tag2_and_bank: // 7
      req_linelock = 1;
      req_tagw = 1;
      tag = tag_reg; tag.dirty = 1; tag_out = tag;
      bank_req_rd = 1;
      bank_data_out = CombineData (port_bsel, data_reg, port_data);
      if (bank_gnt == 1) {
        port_ack = 1;   // can acknowledge to port now (write to bank and tag must be commited!)
        bank_wr = 1;
        next_state = s_wp_init;
      }
      else
        next_state = s_wp_write_bank;
      break;

    case s_wp_write_tag1: // 8
      req_linelock = 1;
      req_tagw = 1;
      tag = tag_reg; tag.dirty = 1; tag_out = tag;
      if (gnt_tagw == 1) {
        tag_wr = 1;
        next_state = s_wp_write_tag2;
      }
      break;

    case s_wp_write_tag2: // 9
      req_linelock = 1;
      req_tagw = 1;
      tag = tag_reg; tag.dirty = 1; tag_out = tag;
      tag_wr = 1;
      port_ack = 1;   // can acknowledge to port now (write to bank and tag must be commited!)
      next_state = s_wp_init;

      // Handle new access...
      if (port_wr == 1) {
        if (port_direct == 1) {
          // Direct (uncached) memory access...
          req_busif = 1;
          busif_op = bioDirectWrite;
          if (gnt_busif == 1 && busif_busy == 0)
            next_state = s_wp_direct;
        }
        else {
          // Normal (cached) access...
          req_linelock = 1;
          tagr_req_rd = 1;
          if (gnt_tagr == 1) {
            if (gnt_linelock == 1) next_state = s_wp_read_tag;
            else next_state = s_wp_request_linelock_only;
          }
        }
      }
      break;

    case s_wp_write_bank: // 10
      req_linelock = 1;
      bank_req_rd = 1;
      bank_wr = 1;
      bank_data_out = CombineData (port_bsel, data_reg, port_data);
      if (bank_gnt == 1) {
        bank_wr = 1;
        port_ack = 1;   // can acknowledge to port now (write to bank must be commited!)
        next_state = s_wp_init;
      }
      // Can we accept a new request already in this state?
      // -> No, 'tagr' must not be requested while bank is held (deadlock)
      break;

    // The following states handle a cache miss & replace a cache line.

    case s_wp_miss: // 11
      // Entry state for a cache miss. First, we must request acquire the BusIf and potentially re-acquire the line lock...
      req_busif = 1;
      req_linelock = 1;
      if (gnt_busif == 1 && busif_busy == 0 && gnt_linelock == 1)
        next_state = s_wp_recheck;
      else
        if (gnt_busif == 0 && gnt_linelock == 1) next_state = s_wp_request_busif_only;
      break;

    case s_wp_request_busif_only: // 12
      // Release the line lock and request the BusIf only to avoid deadlocks.
      req_busif = 1;
      if (gnt_busif == 1) next_state = s_wp_miss;
      break;
  
    case s_wp_recheck: // 13
      // Now we have the BusIf and the line lock, and the BusIf is idle. We must re-check if there is a cache hit now, since
      // some other port may have replaced the cache line in between.
      req_busif = 1;
      req_linelock = 1;
      tagr_req_rd = 1;
      if (gnt_tagr == 1) next_state = s_wp_recheck_read_tag;
      break;
  
    case s_wp_recheck_read_tag: // 14
      // Capture the tag and check it for a cache hit.
      req_busif = 1;
      req_linelock = 1;
      next_tag_reg = tag_in;
      if (tag_in.read ().valid == 1) {
        if (port_bsel.read () == 0xf) {
          if (tag_in.read ().dirty == 1) next_state = s_wp_write_bank;
          else next_state = s_wp_write_tag1_and_bank;
        }
        else next_state = s_wp_have_tag_request_bank;
      }
      else next_state = s_wp_replace;
      break;
  
    case s_wp_replace: // 15
      // Start the replacement by the BusIf.
      req_busif = 1;
      req_linelock = 1;
      busif_op = bioReplace;
      if (busif_busy == 1) next_state = s_wp_replace_wait_busif;
      break;
  
    case s_wp_replace_wait_busif: // 16
      // Wait for the BusIf to complete the replacement.
      req_busif = 1;
      req_linelock = 1;
      if (busif_busy == 0) {
        tagr_req_rd = 1;
        if (gnt_tagr == 1) next_state = s_wp_read_tag;
        else next_state = s_wp_init;
      }
      break;

    // States for special operations...

    case s_wp_special_request_busif_only:   // 17
      req_busif = 1;
      if (gnt_busif == 1) next_state = s_wp_init;
      break;

    case s_wp_special:   // 18
      req_busif = 1;
      req_linelock = 1;
      busif_op = (port_writeback == 1 && port_invalidate == 1) ? bioFlush :
                 (port_writeback == 1) ? bioWriteback : bioInvalidate;
      if (busif_busy == 1)
        next_state = s_wp_special_wait_complete;
      break;
  
    case s_wp_special_wait_complete:   // 19
      req_busif = 1;
      req_linelock = 1;
      if (busif_busy == 0) {
        // The BUSIF has completed -> can ack and complete
        port_ack = 1;
        next_state = s_wp_init;
      }
      break;
  
  }  // switch (state_reg)

  // Set derived outputs...
  req_tagr = tagr_req_rd;
  tag_rd = tagr_req_rd;
  req_bank[bank] = bank_req_rd;
  bank_rd = bank_req_rd;
}




// **************** MArbiter ********************


void MArbiter::Trace (sc_trace_file *tf, int level) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE(tf, clk);
  TRACE(tf, reset);

  TRACE(tf, wiadr_busif);
  TRACE_BUS(tf, wiadr_rp, RPORTS);
  TRACE_BUS(tf, adr_wp, WPORTS);
  TRACE_BUS(tf, way_wp, WPORTS);
  TRACE_BUS_BUS(tf, wiadr_bank, CACHE_BANKS, BR_PORTS);

  //   Write snooping...
  TRACE(tf, snoop_adr);
  TRACE_BUS(tf, snoop_stb, WPORTS);

  //   Line lock...
  TRACE(tf, req_busif_linelock);
  TRACE_BUS(tf, req_wp_linelock, WPORTS);
  TRACE(tf, gnt_busif_linelock);
  TRACE_BUS(tf, gnt_wp_linelock, WPORTS);

  //   Tag RAM...
  TRACE(tf, tagram_ready);
  TRACE(tf, req_busif_tagw);
  TRACE_BUS(tf, req_wp_tagw, WPORTS);
  TRACE(tf, req_busif_tagr);
  TRACE_BUS(tf, req_wp_tagr, WPORTS);
  TRACE_BUS(tf, req_rp_tagr, RPORTS);
  TRACE(tf, gnt_busif_tagw);
  TRACE_BUS(tf, gnt_wp_tagw, WPORTS);
  TRACE(tf, gnt_busif_tagr);
  TRACE_BUS(tf, gnt_wp_tagr, WPORTS);
  TRACE_BUS(tf, gnt_rp_tagr, RPORTS);

  //   Bank RAMs...
  TRACE_BUS(tf, req_busif_bank, CACHE_BANKS);
  TRACE_BUS_BUS(tf, req_wp_bank, WPORTS, CACHE_BANKS);
  TRACE_BUS_BUS(tf, req_rp_bank, RPORTS, CACHE_BANKS);
  TRACE_BUS(tf, gnt_busif_bank, CACHE_BANKS);
  TRACE_BUS_BUS(tf, gnt_wp_bank, WPORTS, CACHE_BANKS);
  TRACE_BUS_BUS(tf, gnt_rp_bank, RPORTS, CACHE_BANKS);

  //   BUSIF...
  TRACE_BUS(tf, req_rp_busif, RPORTS);
  TRACE_BUS(tf, req_wp_busif, WPORTS);
  TRACE_BUS(tf, gnt_rp_busif, RPORTS);
  TRACE_BUS(tf, gnt_wp_busif, WPORTS);

  // Registers...
  TRACE(tf, counter_reg);
  TRACE(tf, linelock_reg);
  TRACE(tf, tagr_reg);
  TRACE(tf, tagw_reg);
  TRACE_BUS(tf, bank_reg, CACHE_BANKS);
  TRACE(tf, busif_reg);

  // Internal signals...
  TRACE(tf, next_linelock_reg);
  TRACE(tf, next_tagr_reg);
  TRACE(tf, next_tagw_reg);
  TRACE_BUS(tf, next_bank_reg, CACHE_BANKS);
  TRACE(tf, next_busif_reg);
}


void MArbiter::LineLockMethod () {
  sc_uint<WPORTS+1> req_linelock, gnt_linelock;
  int n, i;

  // Current policy (to save area):
  // - WPORT requests always exclude each other, indepent of the index adress
  // - concurrent BUSIF and WPORT grants are possible, if they adress different lines

  // Collect all request signals...
  req_linelock[WPORTS] = req_busif_linelock;
  for (n = 0; n < WPORTS; n++) req_linelock[n] = req_wp_linelock[n];

  // Determine existing & to-keep grants...
  gnt_linelock = linelock_reg.read () & req_linelock;

  // Handle BUSIF request (highest priority)...
  if (req_linelock[WPORTS] & !gnt_linelock[WPORTS]) {
    gnt_linelock[WPORTS] = 1;
    for (n = 0; n < WPORTS; n++)
      if (gnt_linelock[n] && GetIndexOfAdr (adr_wp[n]) == GetIndexOfWayIndex (wiadr_busif))
        gnt_linelock[WPORTS] = 0;
  }

  // Handle write port requests...
  for (n = 0; n < WPORTS && gnt_linelock.range(WPORTS-1,0) == 0; n++) {
    i = (n + GetPrioCpu ()) % WPORTS;
    if (req_linelock[i] && (!gnt_linelock[WPORTS] || GetIndexOfAdr (adr_wp[i]) != GetIndexOfWayIndex (wiadr_busif)))
      gnt_linelock[i] = 1;
  }

  // Write results...
  next_linelock_reg = gnt_linelock;

  gnt_busif_linelock = gnt_linelock[WPORTS];
  for (n = 0; n < WPORTS; n++) gnt_wp_linelock[n] = gnt_linelock[n];
}


void MArbiter::TagMethod () {
  sc_uint<RPORTS+WPORTS+1> req_tagr, gnt_tagr;
  sc_uint<WPORTS+1> req_tagw, gnt_tagw;
  int n, i;

  if (tagram_ready == 0) {   // Tag RAM not yet ready...
    gnt_tagr = 0;
    gnt_tagw = 0;
  }
  else {

    // Collect all request signals...
    for (n = 0; n < RPORTS; n++) req_tagr[n] = req_rp_tagr[n];
    for (n = 0; n < WPORTS; n++) {
      req_tagr[RPORTS+n] = req_wp_tagr[n];
      req_tagw[n] = req_wp_tagw[n];
    }
    req_tagr[RPORTS+WPORTS] = req_busif_tagr;
    req_tagw[WPORTS] = req_busif_tagw;

    // Determine existing & to-keep grants...
    gnt_tagr = tagr_reg.read() & req_tagr;
    gnt_tagw = tagw_reg.read() & req_tagw;

    // Handle read requests...
    if (req_tagw == 0) {  // Writer priority: only accept new readers if no write requests are pending...
      for (n = 0; n < CPU_CORES; n++) {   // Select highest priority acquired bit for each CPU
        if (!gnt_tagr[n] && !gnt_tagr[WPORTS+n] && !gnt_tagr[2*WPORTS+n] && (n != CPU_CORES-1 || !gnt_tagr[RPORTS+WPORTS])) {
          // no exisiting grant...
          if (n == CPU_CORES-1 && req_tagr[RPORTS+WPORTS]) // Prio 0: BUSIF (shares port with last CPU)
            gnt_tagr[RPORTS+WPORTS] = 1;
          else if (req_tagr[n])                            // Prio 1: Data read
            gnt_tagr[n] = 1;
          else if (req_tagr[WPORTS+n])                     // Prio 2: Insn read
            gnt_tagr[WPORTS+n] = 1;
          else if (req_tagr[RPORTS+n])                     // Prio 3: Data write
            gnt_tagr[RPORTS+n] = 1;
        }
      }
    }

    // cout << "### tagw_reg = " << tagw_reg << "  req_tagw = " << req_tagw << "  gnt_tagw = " << gnt_tagw << endl;

    // Handle write requests...
    if (gnt_tagr == 0 && gnt_tagw == 0) {    // can only accept new writers if no other reader or writer active
      if (req_tagw[WPORTS])
        gnt_tagw[WPORTS] = 1;   // give BUSIF highest priority (good? -> request may originate from a read miss)
      else {
        for (n = 0; n < WPORTS; n++) {
          i = (n + GetPrioCpu ()) % WPORTS;
          if (req_tagw[i]) {
            gnt_tagw[i] = 1;
            break;
          }
        }
      }
    }
  }

  // Write results...
  next_tagr_reg = gnt_tagr;
  next_tagw_reg = gnt_tagw;

  for (n = 0; n < RPORTS; n++) gnt_rp_tagr[n] = gnt_tagr[n];
  for (n = 0; n < WPORTS; n++) {
    gnt_wp_tagr[n] = gnt_tagr[RPORTS+n];
    gnt_wp_tagw[n] = gnt_tagw[n];
  }
  gnt_busif_tagr = gnt_tagr[RPORTS+WPORTS];
  gnt_busif_tagw = gnt_tagw[WPORTS];
}



// Mappings for the bank ports to the 'req_bank'/'gnt_bank' bus ...
#define IDX_RP(cpu) (cpu)          // data read ports
#define IDX_WP(cpu) (RPORTS+cpu)   // write ports
#define IDX_IP(cpu) (WPORTS+cpu)   // insn read ports
#define IDX_BUSIF (RPORTS+WPORTS)  // BusIF port

#define CPU_OF_IDX(idx) ((idx) % CPU_CORES)

// Mappings of CPUs and BusIf to the bank RAM ports...
#define RAMPORT_BUSIF (BR_PORTS-1)
#define RAMPORT(idx) ((idx) == IDX_BUSIF ? RAMPORT_BUSIF : ((idx) % CPU_CORES) % BR_PORTS)


void MArbiter::BankMethod () {
  sc_uint<RPORTS+WPORTS+1> req_bank, gnt_bank;
  TWord sel_wiadr[BR_PORTS], wiadr[RPORTS+WPORTS+1];
  int sel_port[BR_PORTS];
  int n, b, i, p;

  // Collect all way & index adresses...
  for (n = 0; n < CPU_CORES; n++) {
    wiadr[IDX_RP(n)] = wiadr_rp[n];
    wiadr[IDX_IP(n)] = wiadr_rp[CPU_CORES+n];
    wiadr[IDX_WP(n)] = GetWayIndexOfAdr (adr_wp[n], way_wp[n]);
  }
  wiadr[IDX_BUSIF] = wiadr_busif;

  for (b = 0; b < CACHE_BANKS; b++) {

    // Collect all request signals...
    for (n = 0; n < CPU_CORES; n++) {
      req_bank[IDX_RP(n)] = req_rp_bank[n][b];
      req_bank[IDX_IP(n)] = req_rp_bank[CPU_CORES+n][b];
      req_bank[IDX_WP(n)] = req_wp_bank[n][b];
    }
    req_bank[IDX_BUSIF] = req_busif_bank[b];

    // Determine existing & to-keep grants...
    gnt_bank = bank_reg[b].read () & req_bank;

    // Determine the selected ports...
    for (p = 0; p < BR_PORTS; p++) sel_port[p] = -1;
    for (n = 0; n < RPORTS+WPORTS+1; n++) {                          // Prio -1: already granted ports
      p = RAMPORT(n);
      if (gnt_bank[n] == 1) sel_port[p] = n;
    }
    if (req_bank[IDX_BUSIF] == 1 && sel_port[RAMPORT_BUSIF] < 0)     // Prio 0: BUSIF (prio 0 = good choice for banks?)
      sel_port[RAMPORT_BUSIF] = IDX_BUSIF;
    if (req_bank.value () != 0) for (n = 0; n < CPU_CORES; n++) {
      i = (GetPrioCpu () + n) % CPU_CORES;
      p = RAMPORT(i);
      if (sel_port[p] < 0) {
        if (req_bank[IDX_RP(i)]) sel_port[p] = IDX_RP(i);       // Prio 1: Data read
        else if (req_bank[IDX_IP(i)]) sel_port[p] = IDX_IP(i);  // Prio 2: Insn read
        else if (req_bank[IDX_WP(i)]) sel_port[p] = IDX_WP(i);  // Prio 3: Data write
      }
    }

    // Find selected 'wiadr's & determine all possible grant lines...
    for (p = 0; p < BR_PORTS; p++) {
      if (sel_port[p] >= 0) sel_wiadr[p] = wiadr[sel_port[p]];
      else sel_wiadr[p] = 0xffffffff;    // should be don't care
    }
    for (n = 0; n < RPORTS+WPORTS+1; n++) {
      p = RAMPORT(n);
      if (sel_port[p] >= 0 && req_bank[n] == 1 && wiadr[n] == sel_wiadr[p]) gnt_bank[n] = 1;
      //INFOF (("  n = %i, p = %i, sel_port[p] = %i, sel_wiadr[p] = %x, req_bank[n] = %i, wiadr[n] = %x",
      //        n, p, sel_port[p], sel_wiadr[p], (int) req_bank[n], wiadr[n]));
    }

    //INFOF (("a) req_bank = %x, gnt_bank = %x, sel_port = { %i, %i }, sel_wiadr = { %x, %x }",
    //        (TWord) req_bank.value (), (TWord) gnt_bank.value (), sel_port[0], sel_port[1], sel_wiadr[0], sel_wiadr[1]));
    //cout << gnt_bank << endl;

    // Remove all grants but one for write ports...
    //   (only one grant per bank is possible, so that the 'wdata' bus can be routed correctly)
    //   find the highest-priority write port that has been pre-granted...
    for (n = 0; n < CPU_CORES; n++) {
      i = (GetPrioCpu () + n) % CPU_CORES;
      p = RAMPORT(i);
      if (sel_port[p] != IDX_BUSIF)    // BusIf has highest priority
        if (gnt_bank[IDX_WP(i)] == 1) sel_port[p] = IDX_WP(i);
    }
    //   remove all grants except for the selected one...
    for (n = 0; n < CPU_CORES; n++) {
      p = RAMPORT(n);
      //INFOF (("  checking WP %i against p = %i", IDX_WP(n), p));
      if (sel_port[p] != IDX_WP(n)) gnt_bank[IDX_WP(n)] = 0;
    }
    if (sel_port[RAMPORT_BUSIF] != IDX_BUSIF) gnt_bank[IDX_BUSIF] = 0;
    //INFOF (("b) req_bank = %x, gnt_bank = %x, sel_port = { %i, %i }, sel_wiadr = { %x, %x }",
    //        (TWord) req_bank.value (), (TWord) gnt_bank.value (), sel_port[0], sel_port[1], sel_wiadr[0], sel_wiadr[1]));

    // Write results...
    next_bank_reg[b] = gnt_bank;

    for (n = 0; n < CPU_CORES; n++) {
      gnt_rp_bank[n][b] = gnt_bank[IDX_RP(n)];
      gnt_rp_bank[CPU_CORES+n][b] = gnt_bank[IDX_IP(n)];
      gnt_wp_bank[n][b] = gnt_bank[IDX_WP(n)];
    }
    gnt_busif_bank[b] = gnt_bank[IDX_BUSIF];

    for (p = 0; p < BR_PORTS; p++) wiadr_bank[b][p] = sel_wiadr[p];

    // Check result...
    //for (n = 0; n < RPORTS+WPORTS+1; n++) {
    //  p = RAMPORT(n);
    //  ASSERTF (gnt_bank[n] == 0 || sel_wiadr[p] == wiadr[n], ("grant for cache bank %i given to port %i, but sel_wiadr[%i] = %x and wiadr[%i] = %x\n", b, n, p, sel_wiadr[p], n, wiadr[n]));
    //}
  }
}


void MArbiter::BusIfMethod () {
  sc_uint<RPORTS+WPORTS> req_busif, gnt_busif;
  int n, k, i;

  // Collect all request signals...
  for (n = 0; n < RPORTS; n++) req_busif[n] = req_rp_busif[n];
  for (n = 0; n < WPORTS; n++) req_busif[RPORTS+n] = req_wp_busif[n];

  // Determine existing & to-keep grants...
  gnt_busif = busif_reg.read() & req_busif;

  // Handle new requests...
  for (n = 0; n < CPU_CORES && gnt_busif == 0; n++) {
    i = (n + GetPrioCpu ()) % CPU_CORES;
    if (req_busif[i]) gnt_busif[i] = 1;    // Data read port
    else if (req_busif[CPU_CORES + i]) gnt_busif[CPU_CORES + i] = 1;    // Insn read port
    else if (req_busif[RPORTS + i]) gnt_busif[RPORTS + i] = 1;    // Data write port
    // EXAMINE: Give port type higher priority than cpu no.?
  }

  // Write results...
  next_busif_reg = gnt_busif;

  for (n = 0; n < RPORTS; n++) gnt_rp_busif[n] = gnt_busif[n];
  for (n = 0; n < WPORTS; n++) gnt_wp_busif[n] = gnt_busif[RPORTS+n];
}


void MArbiter::SnoopMethod () {
  int n, writer = -1;

  // Determine a/the writer...
  //   NOTE: only cached writes are supported for snooping (LL/SC)
  for (n = 0; n < WPORTS; n++) {
    if (next_linelock_reg.read() [n] == 1) {   // to catch a writer to the cache
      assert (writer < 0);    // there should be only one!!
      writer = n;
    }
  }

  // Generate output signals...
  if (writer >= 0) {
    snoop_adr = adr_wp[writer];
    for (n = 0; n < WPORTS; n++) snoop_stb[n] = 1;  // signal to all CPUs ...
    snoop_stb [writer] = 0;                         // ... except the one that caused the write to avoid race condition
  }
  else {
    snoop_adr = 0xffffffff; // don't care
    for (n = 0; n < WPORTS; n++) snoop_stb[n] = 0;
  }
}


int MArbiter::GetPrioCpu () {
#if ARBITER_METHOD >= 0   // round robin...
  return (counter_reg.read () >> ARBITER_METHOD) % CPU_CORES;
#else                       // LFSR...
  return counter_reg.read () % CPU_CORES;
#endif
}


void MArbiter::TransitionThread () {
  int n;

  // Reset...
  counter_reg = 0xffff;
  linelock_reg = 0;

  // Main loop...
  while (1) {
    wait ();

    // 'counter_reg'...
#if ARBITER_METHOD >= 0   // round robin...
    counter_reg = (counter_reg + 1) & ((CPU_CORES << ARBITER_METHOD) - 1);
#else                     // LFSR...
    counter_reg = GetNextLfsrState (counter_reg, 16, GetPrimePoly (16, 0));
#endif

    linelock_reg = next_linelock_reg;
    tagr_reg = next_tagr_reg;
    tagw_reg = next_tagw_reg;
    for (n = 0; n < CACHE_BANKS; n++) bank_reg[n] = next_bank_reg[n];
    busif_reg = next_busif_reg;
  }
}





// **************** MMemu ***********************


void MMemu::Trace (sc_trace_file *tf, int levels) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE(tf, clk);
  TRACE(tf, reset);

  //   Bus interface (Wishbone)...
  TRACE(tf, wb_cyc_o);
  TRACE(tf, wb_stb_o);
  TRACE(tf, wb_we_o);
  TRACE(tf, wb_sel_o);
  TRACE(tf, wb_ack_i);
  //TRACE(tf, wb_err_i);
  //TRACE(tf, wb_rty_i);
  TRACE(tf, wb_adr_o);
  TRACE(tf, wb_dat_i);
  TRACE(tf, wb_dat_o);

  //   Read ports...
  TRACE_BUS(tf, rp_rd, RPORTS);
  TRACE_BUS(tf, rp_direct, RPORTS);
  TRACE_BUS(tf, rp_ack, RPORTS);
  TRACE_BUS(tf, rp_bsel, RPORTS);
  TRACE_BUS(tf, rp_adr, RPORTS);
  TRACE_BUS(tf, rp_data, RPORTS);

  //   Write ports...
  TRACE_BUS(tf, wp_wr, WPORTS);
  TRACE_BUS(tf, wp_direct, WPORTS);
  TRACE_BUS(tf, wp_bsel, WPORTS);
  TRACE_BUS(tf, wp_ack, WPORTS);
  TRACE_BUS(tf, wp_rlink_wcond, WPORTS);
  TRACE_BUS(tf, wp_wcond_ok, WPORTS);
  TRACE_BUS(tf, wp_writeback, WPORTS);
  TRACE_BUS(tf, wp_invalidate, WPORTS);
  TRACE_BUS(tf, wp_adr, WPORTS);
  TRACE_BUS(tf, wp_data, WPORTS);

  // Tag RAM...
  TRACE(tf, tagram_ready);
  TRACE_BUS(tf, tagram_rd, TR_PORTS);
  TRACE_BUS(tf, tagram_wr, TR_PORTS);
  TRACE_BUS(tf, tagram_adr, TR_PORTS);
  TRACE_BUS(tf, tagram_tag_in, TR_PORTS);
  TRACE_BUS(tf, tagram_tag_out, TR_PORTS);

  // Bank RAM...
  TRACE_BUS_BUS(tf, bankram_rd, CACHE_BANKS, BR_PORTS);
  TRACE_BUS_BUS(tf, bankram_wr, CACHE_BANKS, BR_PORTS);
  TRACE_BUS_BUS(tf, bankram_wiadr, CACHE_BANKS, BR_PORTS);
  TRACE_BUS_BUS(tf, bankram_wdata, CACHE_BANKS, BR_PORTS);
  TRACE_BUS_BUS(tf, bankram_rdata, CACHE_BANKS, BR_PORTS);

  // BUSIF...
  TRACE(tf, busif_op);
  TRACE(tf, busif_nolinelock);
  TRACE(tf, busif_busy);
  TRACE(tf, busif_tag_rd);
  TRACE(tf, busif_tag_wr);
  TRACE_BUS(tf, busif_bank_rd, CACHE_BANKS);
  TRACE_BUS(tf, busif_bank_wr, CACHE_BANKS);
  TRACE(tf, busif_adr_in);
  TRACE(tf, busif_adr_out);
  TRACE_BUS(tf, busif_data_in, CACHE_BANKS);
  TRACE_BUS(tf, busif_data_out, CACHE_BANKS);
  TRACE_BUS(tf, busif_data_out_valid, CACHE_BANKS);
  TRACE(tf, busif_tag_in);
  TRACE(tf, busif_tag_out);
  TRACE(tf, busif_bsel);

  // Read ports...
  TRACE(tf, rp_busif_data);
  TRACE_BUS(tf, rp_busif_op, RPORTS);
  TRACE_BUS(tf, rp_tag_rd, RPORTS);
  TRACE_BUS(tf, rp_bank_rd, RPORTS);
  TRACE_BUS(tf, rp_tag_in, RPORTS);
  TRACE_BUS(tf, rp_way_out, RPORTS);
  TRACE_BUS(tf, rp_bank_data_in, RPORTS);
  TRACE_BUS(tf, rp_bank_sel, RPORTS);

  // Write ports...
  TRACE_BUS(tf, wp_busif_op, WPORTS);
  TRACE_BUS(tf, wp_busif_nolinelock, WPORTS);
  TRACE_BUS(tf, wp_tag_rd, WPORTS);
  TRACE_BUS(tf, wp_tag_wr, WPORTS);
  TRACE_BUS(tf, wp_bank_rd, WPORTS);
  TRACE_BUS(tf, wp_bank_wr, WPORTS);
  TRACE_BUS(tf, wp_tag_in, WPORTS);
  TRACE_BUS(tf, wp_tag_out, WPORTS);
  TRACE_BUS(tf, wp_bank_data_in, WPORTS);
  TRACE_BUS(tf, wp_bank_data_out, WPORTS);

  // Arbiter: request/grant signals (find comments in 'MArbiter')...
  TRACE(tf, req_busif_linelock);
  TRACE_BUS(tf, req_wp_linelock, WPORTS);
  TRACE(tf, gnt_busif_linelock);
  TRACE_BUS(tf, gnt_wp_linelock, WPORTS);

  TRACE(tf, req_busif_tagw);
  TRACE_BUS(tf, req_wp_tagw, WPORTS);
  TRACE(tf, req_busif_tagr);
  TRACE_BUS(tf, req_wp_tagr, WPORTS);
  TRACE_BUS(tf, req_rp_tagr, RPORTS);
  TRACE(tf, gnt_busif_tagw);
  TRACE_BUS(tf, gnt_wp_tagw, WPORTS);
  TRACE(tf, gnt_busif_tagr);
  TRACE_BUS(tf, gnt_wp_tagr, WPORTS);
  TRACE_BUS(tf, gnt_rp_tagr, RPORTS);

  TRACE_BUS(tf, req_busif_bank, CACHE_BANKS);
  TRACE_BUS_BUS(tf, req_wp_bank, WPORTS, CACHE_BANKS);
  TRACE_BUS_BUS(tf, req_rp_bank, RPORTS, CACHE_BANKS);
  TRACE_BUS(tf, gnt_busif_bank, CACHE_BANKS);
  TRACE_BUS_BUS(tf, gnt_wp_bank, WPORTS, CACHE_BANKS);
  TRACE_BUS_BUS(tf, gnt_rp_bank, RPORTS, CACHE_BANKS);

  TRACE_BUS(tf, req_rp_busif, RPORTS);
  TRACE_BUS(tf, gnt_rp_busif, RPORTS);
  TRACE_BUS(tf, req_wp_busif, WPORTS);
  TRACE_BUS(tf, gnt_wp_busif, WPORTS);

  // Arbiter: other signals ...
  TRACE(tf, wiadr_busif);
  TRACE_BUS(tf, wiadr_rp, RPORTS);
  TRACE_BUS(tf, adr_wp, WPORTS);
  TRACE_BUS(tf, way_wp, WPORTS);
  TRACE(tf, snoop_adr);
  TRACE_BUS(tf, snoop_stb, WPORTS);

  // Sub-Modules...
  if (levels > 1) {
    levels--;
    tagRam->Trace (tf, levels);
    busIf->Trace (tf, levels);
    for (int n = 0; n < RPORTS; n++) readPorts[n]->Trace (tf, levels);
    for (int n = 0; n < WPORTS; n++) writePorts[n]->Trace (tf, levels);
    arbiter->Trace (tf, levels);
  }
}


void MMemu::InitSubmodules () {
  MBankRam *br;
  MReadPort *rp;
  MWritePort *wp;
  char name[80];
  int n, k, b, p;

  // Tag RAM...
  tagRam = new MTagRam ("TagRAM");

  tagRam->clk (clk);
  tagRam->reset (reset);
  tagRam->ready (tagram_ready);
  for (n = 0; n < TR_PORTS; n++) {
    tagRam->rd[n] (tagram_rd[n]);
    tagRam->wr[n] (tagram_wr[n]);
    tagRam->adr[n] (tagram_adr[n]);
    //tagRam->hit[n] (tagram_hit[n]);
    tagRam->tag_in[n] (tagram_tag_in[n]);
    tagRam->tag_out[n] (tagram_tag_out[n]);
  }

  // Bank RAM...
  for (n = 0; n < CACHE_BANKS; n++) {
    sprintf (name, "BankRAM%i", n);
    br = new MBankRam (name);
    bankRam[n] = br;

    br->clk (clk);
    for (k = 0; k < BR_PORTS; k++) {
      br->rd[k] (bankram_rd[n][k]);
      br->wr[k] (bankram_wr[n][k]);
      br->wiadr[k] (bankram_wiadr[n][k]);
      br->wdata[k] (bankram_wdata[n][k]);
      br->rdata[k] (bankram_rdata[n][k]);
    }
  }

  // BUSIF...
  busIf = new MBusIf ("BusIf");

  busIf->clk (clk);
  busIf->reset (reset);

  busIf->wb_cyc_o (wb_cyc_o);
  busIf->wb_stb_o (wb_stb_o);
  busIf->wb_we_o (wb_we_o);
  busIf->wb_sel_o (wb_sel_o);
  busIf->wb_ack_i (wb_ack_i);
  busIf->wb_adr_o (wb_adr_o);
  busIf->wb_dat_i (wb_dat_i);
  busIf->wb_dat_o (wb_dat_o);

  busIf->busif_op (busif_op);
  busIf->busif_nolinelock (busif_nolinelock);
  busIf->busif_bsel (busif_bsel);
  busIf->busif_busy (busif_busy);

  busIf->tag_rd (busif_tag_rd);
  busIf->tag_wr (busif_tag_wr);
  for (n = 0; n < CACHE_BANKS; n++) {
    busIf->bank_rd[n] (busif_bank_rd[n]);
    busIf->bank_wr[n] (busif_bank_wr[n]);
  }
  busIf->adr_in (busif_adr_in);
  busIf->adr_out (busif_adr_out);
  for (n = 0; n < CACHE_BANKS; n++) {
    busIf->data_in[n] (busif_data_in[n]);
    busIf->data_out[n] (busif_data_out[n]);
    busIf->data_out_valid[n] (busif_data_out_valid[n]);
  }
  busIf->tag_in (busif_tag_in);
  busIf->tag_out (busif_tag_out);

  busIf->req_linelock (req_busif_linelock);
  busIf->gnt_linelock (gnt_busif_linelock);
  busIf->req_tagw (req_busif_tagw);
  busIf->gnt_tagw (gnt_busif_tagw);
  busIf->req_tagr (req_busif_tagr);
  busIf->gnt_tagr (gnt_busif_tagr);
  for (n = 0; n < CACHE_BANKS; n++) {
    busIf->req_bank[n] (req_busif_bank[n]);
    busIf->gnt_bank[n] (gnt_busif_bank[n]);
  }

  // Read ports...
  for (n = 0; n < RPORTS; n++) {
    sprintf (name, "ReadPort%i", n);
    rp = new MReadPort (name);
    readPorts[n] = rp;

    rp->clk (clk);
    rp->reset (reset);

    rp->port_rd (rp_rd[n]);
    rp->port_direct (rp_direct[n]);
    rp->port_ack (rp_ack[n]);
    rp->port_adr (rp_adr[n]);
    rp->port_data (rp_data[n]);

    rp->busif_adr (busif_adr_out);
    rp->busif_data (rp_busif_data);
    for (b = 0; b < CACHE_BANKS; b++)
      rp->busif_data_valid[b] (busif_data_out_valid[b]);
    rp->busif_op (rp_busif_op[n]);
    rp->busif_busy (busif_busy);

    rp->tag_rd (rp_tag_rd[n]);
    rp->tag_in (rp_tag_in[n]);
    rp->way_out (rp_way_out[n]);
    rp->bank_rd (rp_bank_rd[n]);
    rp->bank_data_in (rp_bank_data_in[n]);
    rp->bank_sel (rp_bank_sel[n]);

    rp->req_tagr (req_rp_tagr[n]);
    rp->req_busif (req_rp_busif[n]);
    for (k = 0; k < CACHE_BANKS; k++)
      rp->req_bank[k] (req_rp_bank[n][k]);
    rp->gnt_tagr (gnt_rp_tagr[n]);
    rp->gnt_busif (gnt_rp_busif[n]);
    for (k = 0; k < CACHE_BANKS; k++)
      rp->gnt_bank[k] (gnt_rp_bank[n][k]);
  }

  // Write ports...
  for (n = 0; n < WPORTS; n++) {
    sprintf (name, "WritePort%i", n);
    wp = new MWritePort (name);
    writePorts[n] = wp;

    wp->clk (clk);
    wp->reset (reset);

    wp->port_wr (wp_wr[n]);
    wp->port_direct (wp_direct[n]);
    wp->port_bsel (wp_bsel[n]);
    wp->port_ack (wp_ack[n]);
    wp->port_rlink_wcond (wp_rlink_wcond[n]);
    wp->port_wcond_ok (wp_wcond_ok[n]);
    wp->port_writeback (wp_writeback[n]);
    wp->port_invalidate (wp_invalidate[n]);
    wp->port_adr (wp_adr[n]);
    wp->port_data (wp_data[n]);

    wp->busif_adr (busif_adr_out);
    wp->busif_op (wp_busif_op[n]);
    wp->busif_nolinelock (wp_busif_nolinelock[n]);
    wp->busif_busy (busif_busy);

    wp->tag_rd (wp_tag_rd[n]);
    wp->tag_wr (wp_tag_wr[n]);
    wp->tag_in (wp_tag_in[n]);
    wp->tag_out (wp_tag_out[n]);
    wp->bank_rd (wp_bank_rd[n]);
    wp->bank_wr (wp_bank_wr[n]);
    wp->bank_data_in (wp_bank_data_in[n]);
    wp->bank_data_out (wp_bank_data_out[n]);

    wp->req_linelock (req_wp_linelock[n]);
    wp->req_tagr (req_wp_tagr[n]);
    wp->req_tagw (req_wp_tagw[n]);
    wp->req_busif (req_wp_busif[n]);
    for (k = 0; k < CACHE_BANKS; k++)
      wp->req_bank[k] (req_wp_bank[n][k]);
    wp->gnt_linelock (gnt_wp_linelock[n]);
    wp->gnt_tagr (gnt_wp_tagr[n]);
    wp->gnt_tagw (gnt_wp_tagw[n]);
    wp->gnt_busif (gnt_wp_busif[n]);
    for (k = 0; k < CACHE_BANKS; k++)
      wp->gnt_bank[k] (gnt_wp_bank[n][k]);

    wp->snoop_adr (snoop_adr);
    wp->snoop_stb (snoop_stb[n]);
  }

  // Arbiter...
  arbiter = new MArbiter ("Arbiter");

  arbiter->clk (clk);
  arbiter->reset (reset);

  arbiter->tagram_ready (tagram_ready);
  arbiter->wiadr_busif (wiadr_busif);
  arbiter->req_busif_linelock (req_busif_linelock);
  arbiter->gnt_busif_linelock (gnt_busif_linelock);
  arbiter->req_busif_tagw (req_busif_tagw);
  arbiter->req_busif_tagr (req_busif_tagr);
  arbiter->gnt_busif_tagw (gnt_busif_tagw);
  arbiter->gnt_busif_tagr (gnt_busif_tagr);

  arbiter->snoop_adr (snoop_adr);

  for (n = 0; n < RPORTS; n++) {
    arbiter->wiadr_rp[n] (wiadr_rp[n]);
    arbiter->req_rp_tagr[n] (req_rp_tagr[n]);
    arbiter->gnt_rp_tagr[n] (gnt_rp_tagr[n]);
    arbiter->req_rp_busif[n] (req_rp_busif[n]);
    arbiter->gnt_rp_busif[n] (gnt_rp_busif[n]);
  }

  for (n = 0; n < WPORTS; n++) {
    arbiter->adr_wp[n] (adr_wp[n]);
    arbiter->way_wp[n] (way_wp[n]);
    arbiter->req_wp_linelock[n] (req_wp_linelock[n]);
    arbiter->gnt_wp_linelock[n] (gnt_wp_linelock[n]);
    arbiter->req_wp_tagw[n] (req_wp_tagw[n]);
    arbiter->req_wp_tagr[n] (req_wp_tagr[n]);
    arbiter->gnt_wp_tagw[n] (gnt_wp_tagw[n]);
    arbiter->gnt_wp_tagr[n] (gnt_wp_tagr[n]);
    arbiter->req_wp_busif[n] (req_wp_busif[n]);
    arbiter->gnt_wp_busif[n] (gnt_wp_busif[n]);
    arbiter->snoop_stb[n] (snoop_stb[n]);
  }
  for (b = 0; b < CACHE_BANKS; b++) {
    arbiter->req_busif_bank[b] (req_busif_bank[b]);
    arbiter->gnt_busif_bank[b] (gnt_busif_bank[b]);
    for (n = 0; n < RPORTS; n++) {
      arbiter->req_rp_bank[n][b] (req_rp_bank[n][b]);
      arbiter->gnt_rp_bank[n][b] (gnt_rp_bank[n][b]);
    }
    for (n = 0; n < WPORTS; n++) {
      arbiter->req_wp_bank[n][b] (req_wp_bank[n][b]);
      arbiter->gnt_wp_bank[n][b] (gnt_wp_bank[n][b]);
    }
    for (n = 0; n < BR_PORTS; n++)
      arbiter->wiadr_bank[b][n] (bankram_wiadr[b][n]);
  }
}


void MMemu::FreeSubmodules () {
  int n;

  delete tagRam;
  for (n = 0; n < CACHE_BANKS; n++) delete bankRam[n];
  delete busIf;
  for (n = 0; n < RPORTS; n++) delete readPorts[n];
  for (n = 0; n < WPORTS; n++) delete writePorts[n];
  delete arbiter;
}


void MMemu::InitInterconnectMethod () {
  int n, k;

  SC_METHOD (InterconnectMethod);

  // Tag RAM...
  for (n = 0; n < TR_PORTS; n++)
    sensitive << tagram_tag_out[n];

  // Bank RAM...
  for (n = 0; n < CACHE_BANKS; n++)
    for (k = 0; k < BR_PORTS; k++)
      sensitive << bankram_rdata[n][k];

  // BUSIF...
  sensitive << busif_busy << busif_tag_rd << busif_tag_wr << busif_adr_out << busif_tag_out;
  for (n = 0; n < CACHE_BANKS; n++)
    sensitive << busif_bank_rd[n] << busif_bank_wr[n] << busif_data_out[n] << busif_data_out_valid[n];

  // Read ports...
  for (n = 0; n < RPORTS; n++)
    sensitive << rp_busif_op[n] << rp_tag_rd[n] << rp_bank_rd[n] << rp_adr[n] << rp_way_out[n] << rp_bank_sel[n];

  // Write ports...
  for (n = 0; n < WPORTS; n++)
    sensitive << wp_busif_op[n] << wp_busif_nolinelock[n] << wp_tag_rd[n] << wp_tag_wr[n]
      << wp_bank_rd[n] << wp_bank_wr[n] << wp_tag_out[n] << wp_bank_data_out[n]
      << wp_adr[n] << wp_data[n];

  // Arbiter: request/grant signals ...
  sensitive << gnt_busif_linelock << gnt_busif_tagw << gnt_busif_tagr;
  for (n = 0; n < RPORTS; n++)
    sensitive << gnt_rp_tagr[n] << gnt_rp_busif[n];
  for (n = 0; n < WPORTS; n++) {
    sensitive << gnt_wp_linelock[n] << gnt_wp_tagw[n] << gnt_wp_tagr[n] << gnt_wp_busif[n];
    for (k = 0; k < CACHE_BANKS; k++)
      sensitive << gnt_wp_bank[n][k] << gnt_rp_bank[n][k];
  }
  for (n = 0; n < CACHE_BANKS; n++) {
    sensitive << gnt_busif_bank[n];
    for (k = 0; k < BR_PORTS; k++)
      sensitive << bankram_wiadr[n][k];
  }
}


void MMemu::InterconnectMethod () {
  TWord busif_adr_in_var;  // TBD: eliminate
  bool x;
  int n, b, p, cpu;

  // To Tag RAM...
  for (n = 0; n < CPU_CORES; n++) {
    tagram_rd[n] =
      (n == CPU_CORES-1 ? busif_tag_rd : false) |
      rp_tag_rd[n] | rp_tag_rd[CPU_CORES+n] | wp_tag_rd[n];
    tagram_wr[n] =
      (n == CPU_CORES-1 ? busif_tag_wr : false) |
      wp_tag_wr[n];
    tagram_adr[n] =
      n == CPU_CORES-1 && (gnt_busif_tagr || gnt_busif_tagw) ? busif_adr_out :
      gnt_wp_tagr[n] | gnt_wp_tagw[n] ? wp_adr[n] :
      gnt_rp_tagr[n]                  ? rp_adr[n] :
      gnt_rp_tagr[CPU_CORES+n]        ? rp_adr[CPU_CORES+n] :
      0xffffffff;   // don't care
    tagram_tag_in[n] =
      n == CPU_CORES-1 && gnt_busif_tagw ? busif_tag_out :
      wp_tag_out[n];
  }

  // To Bank RAM...
  for (b = 0; b < CACHE_BANKS; b++) {
    for (p = 0; p < BR_PORTS; p++) {
      // defaults...
      bankram_rd[b][p] = 0;
      bankram_wr[b][p] = 0;
      //bankram_wiadr[b][p] = 0xffffffff;     // don't care
      bankram_wdata[b][p] = 0xffffffff;     // don't care
      // find CPU...
      for (cpu = p; cpu < CPU_CORES; cpu += BR_PORTS) {
        if (gnt_rp_bank[cpu][b] == 1) {
          if (rp_bank_rd[cpu] == 1) bankram_rd[b][p] = 1;
        }
        if (gnt_rp_bank[CPU_CORES+cpu][b] == 1) {
          if (rp_bank_rd[CPU_CORES+cpu] == 1) bankram_rd[b][p] = 1;
        }
        if (gnt_wp_bank[cpu][b] == 1) {
          if (wp_bank_rd[cpu] == 1) bankram_rd[b][p] = 1;
          if (wp_bank_wr[cpu] == 1) bankram_wr[b][p] = 1;
          bankram_wdata[b][p] = wp_bank_data_out[cpu];
        }
      }
    }
    // eventually link BUSIF to last port...
    if (gnt_busif_bank[b] == 1) {
      if (busif_bank_rd[b] == 1) bankram_rd[b][BR_PORTS-1] = 1;
      if (busif_bank_wr[b] == 1) bankram_wr[b][BR_PORTS-1] = 1;
      bankram_wdata[b][BR_PORTS-1] = busif_data_out[b];
    }
  }

  // To BUSIF...
  //   defaults ...
  busif_op = bioNothing;
  busif_nolinelock = 0;
  busif_adr_in_var = 0;
  busif_bsel = 0;
  //   from tag RAMs...
  busif_tag_in = tagram_tag_out[CPU_CORES-1];
  //   from bank RAMs...
  for (b = 0; b < CACHE_BANKS; b++) busif_data_in[b] = bankram_rdata[b][BR_PORTS-1];
  //   from read ports...
  for (p = 0; p < RPORTS; p++) if (gnt_rp_busif[p]) {
    busif_op = rp_busif_op[p];
    busif_nolinelock = 0;
    busif_adr_in_var = rp_adr[p];
    busif_bsel = rp_bsel[p];
  }
  //   from write ports...
  for (p = 0; p < WPORTS; p++) if (gnt_wp_busif[p]) {
    busif_op = wp_busif_op[p];
    busif_nolinelock = wp_busif_nolinelock[p];
    busif_adr_in_var = wp_adr[p];
    for (b = 0; b < CACHE_BANKS; b++)
      if (busif_bank_rd[b] == 0) busif_data_in[b] = wp_data[p];
    busif_bsel = wp_bsel[p];
  }
  busif_adr_in = busif_adr_in_var;

  // To read ports...
  for (p = 0; p < RPORTS; p++) {
    cpu = p % CPU_CORES;
    rp_tag_in[p] = tagram_tag_out[cpu];
    rp_bank_data_in[p] = bankram_rdata[rp_bank_sel[p].read ()][cpu % BR_PORTS];
  }
  rp_busif_data = busif_data_out[GetBankOfAdr (busif_adr_out)];

  // To write ports...
  for (p = 0; p < WPORTS; p++) {
    cpu = p;
    wp_tag_in[p] = tagram_tag_out[cpu];
    wp_bank_data_in[p] = bankram_rdata[GetBankOfAdr (wp_adr[p])][cpu % BR_PORTS];
  }

  // To arbiter ...
  wiadr_busif = GetWayIndexOfAdr (busif_adr_out, busif_tag_out.read ().way);
  for (p = 0; p < RPORTS; p++)
    wiadr_rp[p] = GetWayIndexOfAdr (rp_adr[p], rp_way_out[p]);
  for (p = 0; p < WPORTS; p++) {
    adr_wp[p] = wp_adr[p];
    way_wp[p] = wp_tag_out[p].read ().way;
  }
}
