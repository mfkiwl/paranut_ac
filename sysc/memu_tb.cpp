/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This is a test bench for the memory unit (MEMU) of the ParaNut.

 *************************************************************************/


#include "memu.h"
#include "peripherals.h"

#include <systemc.h>

#include <stdio.h>





// **************** Signals *********************


sc_signal<bool> clk, reset;

// WB / memory...
sc_signal<bool> wb_cyc, wb_stb, wb_we, wb_ack, wb_err, wb_rty;
sc_signal<sc_uint<4> > wb_sel;
sc_signal<TWord> wb_adr, wb_dat_w, wb_dat_r;

// CPU - Read ports...
sc_signal<bool> rp_rd [RPORTS], rp_direct [RPORTS];
sc_signal<bool> rp_ack [RPORTS];
sc_signal<sc_uint<4> > rp_bsel [RPORTS];
sc_signal<TWord> rp_adr [RPORTS];
sc_signal<TWord> rp_data [RPORTS];

// CPU - Write ports...
sc_signal<bool> wp_wr [WPORTS], wp_direct [WPORTS];
sc_signal<sc_uint<4> > wp_bsel [WPORTS];
sc_signal<bool> wp_ack [WPORTS];
sc_signal<bool> wp_rlink_wcond [WPORTS];
sc_signal<bool> wp_wcond_ok [WPORTS];
sc_signal<bool> wp_writeback [WPORTS], wp_invalidate [WPORTS];
sc_signal<TWord> wp_adr [WPORTS];
sc_signal<TWord> wp_data [WPORTS];





// **************** Helpers *********************


#define CLK_PERIOD 10.0
//#define CLK_PERIOD (sc_time (10.0, SC_NS).to_double ())


void run_cycle (int n = 1) {
  for (int k = 0; k < n; k++) {
    clk = 1;
    sc_start (CLK_PERIOD / 2, SC_NS);
    clk = 0;
    sc_start (CLK_PERIOD / 2, SC_NS);
  }
}



// ***** Init *****


void ClearReadPort (int p) {
  rp_rd[p] = rp_direct[p] = 0;
  rp_bsel[p] = 0;
  rp_adr[p] = 0;
}


void ClearWritePort (int p) {
  wp_wr[p] = wp_direct[p] = 0;
  wp_bsel[p] = 0;
  wp_rlink_wcond[p] = 0;
  wp_writeback[p] = wp_invalidate[p] = 0;
  wp_adr[p] = wp_data[p] = 0;
}



// ***** Read *****


static void ReadInit (int p, TWord adr, sc_uint<4> bsel = 0xf) {
  rp_adr[p] = adr;
  rp_bsel[p] = bsel;
  rp_rd[p] = 1;
}


static bool ReadCheckAck (int p) {
  if (rp_ack[p] == 1) {
    rp_rd[p] = 0;
    rp_adr[p] = 0xffffffff;   // change adress to verify that in the delayed cycle the adress is not used
    return true;
  }
  else return false;
}


static inline TWord ReadGetData (int p) {
  return rp_data[p];
}


static TWord ReadComplete (int p) {
  TWord data;

  do { run_cycle (); } while (!ReadCheckAck (p));
  run_cycle ();
  return ReadGetData (p);;
}


static TWord Read (int p, TWord adr, sc_uint<4> bsel = 0xf) {
  TWord data;

  ReadInit (p, adr, bsel);
  data = ReadComplete (p);
  // printf ("### Read (0x%08x) = 0x%08x\n", adr, data);
  return data;
}



// ***** Write *****


void WriteInit (int p, TWord adr, TWord data, sc_uint<4> bsel = 0xf) {
  wp_adr[p] = adr;
  wp_data[p] = data;
  wp_bsel[p] = bsel;
  wp_wr[p] = 1;
}


void WriteInitSpecial (int p, TWord adr, bool writeback, bool invalidate) {
  wp_adr[p] = adr;
  wp_writeback[p] = writeback;
  wp_invalidate[p] = invalidate;
}


bool WriteTryComplete (int p) {
  if (wp_ack[p].read ()) {
    wp_wr[p] = 0;
    wp_writeback[p] = 0;
    wp_invalidate[p] = 0;
    return true;
  }
  else return false;
}


void WriteComplete (int p) {
  do { run_cycle (); } while (!WriteTryComplete (p));
}


void Write (int p, TWord adr, TWord data, sc_uint<4> bsel = 0xf) {
  WriteInit (p, adr, data, bsel);
  WriteComplete (p);
  // printf ("### Write (0x%08x) = 0x%08x\n", adr, data);
}


void WriteSpecial (int p, TWord adr, bool writeback, bool invalidate) {
  WriteInitSpecial (p, adr, writeback, invalidate);
  WriteComplete (p);
}




// ****** run_test ******


void RunPartwordReadWrite (int port, TByte id, TWord base, TWord stride = 4, int count = 1) {
  TWord data;
  int n;

  // Write & Read full words...
  INFO ("    write & read full words ...");
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x01010101 * (id + 4 * n) + 0x00010203);
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride);
    ASSERT (data == 0x01010101 * (id + 4 * n) + 0x00010203);
  }

  // Read half words...
  INFO ("    write words & read as half words...");
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x01010101 * (id + 4 * n) + 0x00010203);
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride, 0x3);
    ASSERT ((data & 0xffff0000) == 0x01010000 * (id + 4 * n) + 0x00010000);
  }
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride, 0xc);
    ASSERT ((data & 0x0000ffff) == 0x00000101 * (id + 4 * n) + 0x00000203);
  }
  base += count * stride;
  id += 4 * count;

  // Read bytes...
  INFO ("    write words & read as bytes...");
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x01010101 * (id + 4 * n) + 0x00010203);
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride, 0x1);
    ASSERT ((data & 0xff000000) == 0x01000000 * (id + 4 * n) + 0x00000000);
  }
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride, 0x2);
    ASSERT ((data & 0x00ff0000) == 0x00010000 * (id + 4 * n) + 0x00010000);
  }
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride, 0x4);
    ASSERT ((data & 0x0000ff00) == 0x00000100 * (id + 4 * n) + 0x00000200);
  }
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride, 0x8);
    ASSERT ((data & 0x000000ff) == 0x00000001 * (id + 4 * n) + 0x00000003);
  }
  base += count * stride;
  id += 4 * count;

  // Write half words...
  INFO ("    write half words & read as words...");
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x01010000 * (id + 4 * n) + 0x00010000, 0x3);
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x00000101 * (id + 4 * n) + 0x00000203, 0xc);
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride);
    ASSERT (data == 0x01010101 * (id + 4 * n) + 0x00010203);
  }
  base += count * stride;
  id += 4 * count;

  // Write bytes...
  INFO ("    write bytes & read as words...");
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x01000000 * (id + 4 * n) + 0x00000000, 0x1);
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x00010000 * (id + 4 * n) + 0x00010000, 0x2);
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x00000100 * (id + 4 * n) + 0x00000200, 0x4);
  for (n = 0; n < count; n++)
    Write (port, base + n * stride, 0x00000001 * (id + 4 * n) + 0x00000003, 0x8);
  for (n = 0; n < count; n++) {
    data = Read (port, base + n * stride);
    ASSERT (data == 0x01010101 * (id + 4 * n) + 0x00010203);
  }
  base += count * stride;
  id += 4 * count;
}


void RunParallelReadWrite (TWord id, TWord base0, TWord stride0, TWord base1, TWord stride1) {
  TWord data;
  int n, completed, now_completed;

  // Parallel write...
  INFO ("    parallel write...");
  for (n = 0; n < CPU_CORES; n++)
    WriteInit (n, base0 + stride0 * n, id + n);
  completed = 0;
  while (completed != (1 << CPU_CORES)-1) {
    for (n = 0; n < CPU_CORES; n++)
      if (WriteTryComplete (n)) completed |= 1 << n;
    run_cycle ();
  }

  // Parallel read (data ports)...
  INFO ("    parallel read (data ports)...");
  for (n = 0; n < CPU_CORES; n++)
    ReadInit (n, base0 + stride0 * n);
  completed = 0;
  while (completed != (1 << CPU_CORES)-1) {
    now_completed = 0;
    for (n = 0; n < CPU_CORES; n++) {
      if (ReadCheckAck (n)) {
        now_completed |= 1 << n;
      }
    }
    completed |= now_completed;
    run_cycle ();
    for (n = 0; n < CPU_CORES; n++) if (now_completed & (1 << n))
      ASSERT (ReadGetData (n) == id + n);
  }

  // Parallel write & read (insn ports)...
  INFO ("    parallel write & read (insn ports)...");
  for (n = 0; n < CPU_CORES; n++) {
    WriteInit (n, base1 + stride1 * n, id + CPU_CORES + n);
    ReadInit (CPU_CORES + n, base0 + stride0 * n);
  }
  completed = 0;
  while (completed != (1 << (2*CPU_CORES))-1) {
    now_completed = 0;
    for (n = 0; n < CPU_CORES; n++) {
      if (WriteTryComplete (n)) {
        ASSERTM (completed & (1 << (CPU_CORES+n)), "Direct write completes before direct read: wrong priority");
        completed |= 1 << n;
      }
      if (ReadCheckAck (CPU_CORES + n)) {
        now_completed |= 1 << (CPU_CORES + n);
      }
    }
    completed |= now_completed;
    run_cycle ();
    for (n = 0; n < CPU_CORES; n++) if (now_completed & (1 << (CPU_CORES + n)))
      ASSERT (ReadGetData (CPU_CORES + n) == id + n);
  }

  // Parallel read (data ports) to verify the last writes...
  INFO ("    parallel read (data ports) to verify the last writes...");
  for (n = 0; n < CPU_CORES; n++) {
    ReadInit (CPU_CORES + n, base0 + stride0 * n);
    ReadInit (n, base1 + stride1 * n);
  }
  completed = 0;
  while (completed != (1 << (2*CPU_CORES)) - 1) {
    now_completed = 0;
    for (n = 0; n < CPU_CORES; n++) {
      if (ReadCheckAck (CPU_CORES + n)) now_completed |= 1 << (CPU_CORES + n);
      if (ReadCheckAck (n)) now_completed |= 1 << n;
    }
    completed |= now_completed;
    run_cycle ();
    for (n = 0; n < CPU_CORES; n++) {
      if (now_completed & (1 << (CPU_CORES + n)))
        ASSERT (ReadGetData (CPU_CORES + n) == id + n);
      if (now_completed & (1 << n))
        ASSERT (ReadGetData (n) == id + CPU_CORES + n);
    }
  }
}


static inline int GetRandom (int max) {
  return random () % max;
}


void RunRandomReadWrite (TWord adrRange, int iterations) {    // iterations must be << adrRange/4!
  int toWait[RPORTS], toRead[RPORTS], toWrite[WPORTS], readIdx[RPORTS], writeIdx[WPORTS];
  bool rpAck[RPORTS];
  TWord *adrList, *dataList;
  TWord adr, data;
  bool *adrUsed, *readableList;
  char buf[80];
  int writePtr, n, idx, loops;
  bool done;

  while (iterations > 0) {
    sprintf (buf, "  %i iterations left", iterations);
    INFO (buf);
    loops = adrRange / 4;
    if (loops > iterations) loops = iterations;
    if (loops > 1000) loops = 1000;
    iterations -= loops;

    // Create random data...
    adrUsed = new bool [adrRange];
    for (n = 0; n < adrRange / sizeof(TWord); n++) adrUsed[n] = false;
    adrList = new TWord [loops];
    dataList = new TWord [loops];
    for (n = 0; n < loops; n++) {
      do { adr = GetRandom (adrRange); } while (adrUsed[adr / sizeof(TWord)]);
      adrUsed[adr / sizeof(TWord)] = true;
      adrList[n] = adr & ~3;
      dataList[n] = (TWord) random ();
    }
    delete [] adrUsed;
    readableList = new bool[loops];
    for (n = 0; n < loops; n++) readableList[n] = 0;
  
    // Init state...
    writePtr = 0;
    for (n = 0; n < RPORTS; n++) {
      toWait[n] = toRead[n] = 0;
      rpAck[n] = false;
    }
    for (n = 0; n < WPORTS; n++) toWrite[n] = 0;
    done = false;
  
    // Main loop...
    do {
      for (n = 0; n < RPORTS; n++) {
  
        // Handle state actions...
        if (toWait[n] > 0) {   // State is "waiting" (for read or write)
          toWait[n]--;
          if (toWait[n] <= 0) {
            if (n < WPORTS && toWrite[n] > 0) {
              // Issue a new write operation...
              if (writePtr < loops) {
                WriteInit (n, adrList[writePtr], dataList[writePtr]);
                writeIdx[n] = writePtr;
                writePtr++;
              }
              else {
                toWrite[n] = 0;
                toWait[n] = 1;  // set state to "waiting"
              }
            }
            else if (toRead[n] > 0) {
              // Issue a new read operation...
              if (writePtr > 0) {
                idx = GetRandom (writePtr);
                while (idx >= 0 && !readableList[idx]) idx--;
              }
              else idx = -1;
              if (idx < 0)
                toWait[n] = GetRandom (10) + 1;    // no readable adresses yet
              else {
                readIdx[n] = idx;
                ReadInit (n, adrList[idx]);
              }
            }
          }
        }
        else if (n < WPORTS && toWrite[n] > 0) { // State is "writing"...
          if (WriteTryComplete (n)) {
            readableList[writeIdx[n]] = true;
            toWrite[n]--;
            toWait[n] = GetRandom (4) + 1;   // set state to "waiting"
          }
        }
        else if (toRead[n] > 0) {  // State is "reading"...
          if (rpAck[n]) {
            ASSERTF (ReadGetData (n) == dataList[readIdx[n]],
                     ("port #%i read wrong data from adress %08x: read %08x instead of %08x",
                      n, adrList[readIdx[n]], data, dataList[readIdx[n]]));
            toRead[n]--;
            toWait[n] = GetRandom (4) + 1;   // set state to "waiting"
          }
          rpAck[n] = ReadCheckAck (n);
        }
        else {   // State is "all counters zero"
          if (writePtr < loops) {
            toWait[n] = GetRandom (4) + 1;   // set state to "waiting"
            if (n < WPORTS) toWrite[n] = GetRandom (4) + 1;
            toRead[n] = (n >= WPORTS) ? 1 : (GetRandom (4) + 1);
          }
        }
      }
      run_cycle ();
  
      // Check if we're done...
      if (writePtr < loops) done = false;
      else {
        done = true;
        for (n = 0; n < WPORTS; n++) if (toWrite[n]) done = false;
        for (n = 0; n < RPORTS; n++) if (toRead[n]) done = false;
      }
    } while (!done);
  
    // Final read run to check that everything was written properly...
    for (n = 0; n < loops; n++) {
      data = Read (0, adrList[n]);
      ASSERTF (data == dataList[n],
               ("port #0 read wrong data from adress %08x: read %08x instead of %08x",
                adrList[n], data, dataList[n]));
    }

    // Free ...
    delete [] adrList;
    delete [] dataList;
    delete [] readableList;
  }
}


void RunPerformanceTest (TWord adr, TWord id) {
  char buf[80];
  double t0, t1;
  TWord completed, now_completed, data, idx[WPORTS], lastIdx[WPORTS];
  int n, k, itN, itK, count, set;

  // single-port sequential write & read (no cache misses)...
  itN = CACHE_BANKS * CACHE_SETS;
  sprintf (buf, "  sequentially accessing %i words", itN);
  INFO (buf);
  for (k = 0; k < 2; k++) {   // write twice to have no misses in the second run
    t0 = sc_time_stamp ().to_double ();
    for (n = 0; n < itN; n++)
      Write (0, adr + 4 * n, id + n);
    t1 = sc_time_stamp ().to_double ();
    sprintf (buf, "    writing, run %i: %.2lf clocks/operation", k, (t1-t0) / itN / CLK_PERIOD);
    INFO (buf);
  }
  t0 = sc_time_stamp ().to_double ();
  ReadInit (0, adr);
  for (n = 0; n < itN; n++) {
    while (!ReadCheckAck (0)) run_cycle ();
    if (n < itN-1) ReadInit (0, adr + 4 * (n + 1));
    else t1 = sc_time_stamp ().to_double ();
    run_cycle ();
    ASSERT (ReadGetData (0) == id + n);
  }
  sprintf (buf, "    reading: %.2lf clocks/operation", (t1-t0) / itN / CLK_PERIOD);
  INFO (buf);
  id += 0x10000;

  // single-port sequential write & read (check replacement for multi-way caches)...
  if (CACHE_WAYS > 1) {
    itN = CACHE_BANKS * CACHE_SETS * CACHE_WAYS;
    sprintf (buf, "  sequentially accessing %i words", itN);
    INFO (buf);
    for (k = 0; k < 2; k++) {   // write twice to have no cold misses in the second run
      t0 = sc_time_stamp ().to_double ();
      for (n = 0; n < itN; n++)
        Write (0, adr + 4 * n, id + n);
      t1 = sc_time_stamp ().to_double ();
      sprintf (buf, "    writing, run %i: %.2lf clocks/operation", k, (t1-t0) / itN / CLK_PERIOD);
      INFO (buf);
    }
    t0 = sc_time_stamp ().to_double ();
    ReadInit (0, adr);
    for (n = 0; n < itN; n++) {
      while (!ReadCheckAck (0)) run_cycle ();
      if (n < itN-1) ReadInit (0, adr + 4 * (n + 1));
      else t1 = sc_time_stamp ().to_double ();
      run_cycle ();
      ASSERT (ReadGetData (0) == id + n);
    }
    sprintf (buf, "    reading: %.2lf clocks/operation", (t1-t0) / itN / CLK_PERIOD);
    INFO (buf);
  }
  id += 0x10000;

  // Parallel writing and reading...
  itN = CACHE_BANKS * CACHE_SETS / WPORTS;
  sprintf (buf, "  parallel writes and reads: %i words, %i ports", itN * WPORTS, WPORTS);
  INFO (buf);

  // ... write adjacent...
  t0 = sc_time_stamp ().to_double ();
  for (n = 0; n < itN; n++) {
    for (k = 0; k < WPORTS; k++)
      WriteInit (k, adr + 4 * (WPORTS * n + k), id + WPORTS * n + k);
    completed = 0;
    while (completed != (1 << WPORTS) - 1) {
      run_cycle ();
      for (k = 0; k < WPORTS; k++)
        if (WriteTryComplete (k)) completed |= (1 << k);
      //if (completed != (1 << WPORTS) - 1) run_cycle ();
    }
  }
  t1 = sc_time_stamp ().to_double ();
  sprintf (buf, "    writing (adjacent words): %.2lf clocks/operation", (t1-t0) / itN / CLK_PERIOD);
  INFO (buf);

  // ... read adjacent...
  t0 = sc_time_stamp ().to_double ();
  for (k = 0; k < WPORTS; k++)
    ReadInit (k, adr + 4 * k);
  for (n = 0; n < itN; n++) {
    completed = 0;
    while (completed != (1 << WPORTS) - 1) {
      now_completed = 0;
      for (k = 0; k < WPORTS; k++)
        if (ReadCheckAck (k)) now_completed |= (1 << k);
      completed |= now_completed;
      if (completed == (1 << WPORTS) - 1) {
        if (n < itN-1) {
          for (k = 0; k < WPORTS; k++)
            ReadInit (k, adr + 4 * (WPORTS * (n+1) + k));
        }
        else
          t1 = sc_time_stamp ().to_double ();
      }
      run_cycle ();
      for (k = 0; k < WPORTS; k++) if (now_completed & (1 << k))
        ASSERT(ReadGetData (k) == id + WPORTS * n + k);
    }
  }
  sprintf (buf, "    reading (adjacent words): %.2lf clocks/operation", (t1-t0) / itN / CLK_PERIOD);
  INFO (buf);

  id += 0x10000;

  // ... write, different sets & banks...
  t0 = sc_time_stamp ().to_double ();
  for (n = 0; n < itN; n++) {
    for (k = 0; k < WPORTS; k++) {
      set = (n + k * CACHE_BANKS / WPORTS) % itN;
      WriteInit (k, adr + 4 * (WPORTS * set + k), id + WPORTS * set + k);
    }
    completed = 0;
    while (completed != (1 << WPORTS) - 1) {
      run_cycle ();
      for (k = 0; k < WPORTS; k++)
        if (WriteTryComplete (k)) completed |= (1 << k);
      //if (completed != (1 << WPORTS) - 1) run_cycle ();
    }
  }
  t1 = sc_time_stamp ().to_double ();
  sprintf (buf, "    writing (different sets & banks): %.2lf clocks/operation", (t1-t0) / itN / CLK_PERIOD);
  INFO (buf);

  // ... read same
  t0 = sc_time_stamp ().to_double ();
  for (k = 0; k < WPORTS; k++)
    ReadInit (k, adr + 4 * 0);
  for (n = 0; n < itN * WPORTS; n++) {
    completed = 0;
    while (completed != (1 << WPORTS) - 1) {
      now_completed = 0;
      for (k = 0; k < WPORTS; k++)
        if (ReadCheckAck (k)) now_completed |= (1 << k);
      completed |= now_completed;
      if (completed == (1 << WPORTS) - 1) {
        if (n < itN * WPORTS - 1) {
          for (k = 0; k < WPORTS; k++)
            ReadInit (k, adr + 4 * (n+1));
        }
        else
          t1 = sc_time_stamp ().to_double ();
      }
      run_cycle ();
      for (k = 0; k < WPORTS; k++) if (now_completed & (1 << k))
        ASSERT(ReadGetData (k) == id + n);
    }
  }
  sprintf (buf, "    reading (same words): %.2lf clocks/operation", (t1-t0) / itN / WPORTS / CLK_PERIOD);
  INFO (buf);

  // ... read random
  t0 = sc_time_stamp ().to_double ();
  for (k = 0; k < WPORTS; k++) {
    idx[k] = GetRandom (itN * WPORTS);
    ReadInit (k, adr + 4 * idx[k]);
  }
  for (n = 0; n < itN * WPORTS; n++) {
    completed = 0;
    while (completed != (1 << WPORTS) - 1) {
      now_completed = 0;
      for (k = 0; k < WPORTS; k++)
        if (ReadCheckAck (k)) now_completed |= (1 << k);
      completed |= now_completed;
      for (k = 0; k < WPORTS; k++) lastIdx[k] = idx[k];
      if (completed == (1 << WPORTS) - 1) {
        if (n < itN * WPORTS - 1) {
          for (k = 0; k < WPORTS; k++) {
            idx[k] = GetRandom (itN * WPORTS);
            ReadInit (k, adr + 4 * idx[k]);
          }
        }
        else
          t1 = sc_time_stamp ().to_double ();
      }
      run_cycle ();
      for (k = 0; k < WPORTS; k++) if (now_completed & (1 << k))
        ASSERT(ReadGetData (k) == id + lastIdx[k]);
    }
  }
  sprintf (buf, "    reading (random words): %.2lf clocks/operation", (t1-t0) / itN / WPORTS / CLK_PERIOD);
  INFO (buf);
}


void RunSpecial (int port, TWord adr, TWord id) {

  // Check "invalidate"...
  INFO ("  checking 'invalidate'...");
  Write (port, adr, id);   // write 'id' to cache
  wp_direct[port] = 1;
  Write (port, adr, id+1); // write 'id+1' to main memory
  wp_direct[port] = 0;
  ASSERTM (Read (port, adr) == id, "Direct write affects cache - cannot check 'invalidate'");
  WriteSpecial (port, adr, 0, 1);   // invoke 'invalidate'
  ASSERTM (Read (port, adr) == id+1, "Special operation 'invalidate' does not work");

  // Check "writeback"...
  INFO ("  checking 'writeback'...");
  Write (port, adr, id+2);  // write 'id+2' to cache (main memory holds 'id+1')
  rp_direct[port] = 1;
  ASSERTM (Read (port, adr) == id+1, "Cached write affects main memory - cannot check 'writeback'");
  rp_direct[port] = 0;
  WriteSpecial (port, adr, 1, 0);   // invoke 'writeback'
  rp_direct[port] = 1;
  ASSERTM (Read (port, adr) == id+2, "Special operation 'writeback' does not work");
  rp_direct[port] = 0;

  // Check "flush"...
  INFO ("  checking 'flush'...");
  Write (port, adr, id+3);  // write 'id+3' to cache (main memory holds 'id+2')
  WriteSpecial (port, adr, 1, 1);   // invoke 'flush'
  rp_direct[port] = 1;
  ASSERTM (Read (port, adr) == id+3, "Special operation 'flush' does not write back");
  rp_direct[port] = 0;
  wp_direct[port] = 1;
  Write (port, adr, id+4);  // write 'id+4' to main memory, the next read must cause a miss and this value to be loaded
  wp_direct[port] = 0;
  ASSERTM (Read (port, adr) == id+4, "Special operation 'flush' does not invalidate");
}


void RunLlSc (TWord adr, TWord id) {

  // Initialize adress...
  Write (0, adr, id);

  // Simulate LL...
  wp_rlink_wcond[0] = 1;
  wp_adr[0] = adr;
  ASSERT (Read (0, adr) == id);
  wp_rlink_wcond[0] = 0;

  // Perform successful WC...
  wp_rlink_wcond[0] = 1;
  Write (0, adr, id+1);
  wp_rlink_wcond[0] = 0;
  ASSERTM (wp_wcond_ok[0] == 1, "'wcond_ok' not set after successful write-conditional");
  ASSERTM (Read (0, adr) == id+1, "memory not changed after sucessful write-conditional");

  // Perform concurrent write through other port...
  Write (1, adr, id+2);

  // Perform failing WC...
  wp_rlink_wcond[0] = 1;
  Write (0, adr, id+3);
  wp_rlink_wcond[0] = 0;
  ASSERTM (wp_wcond_ok[0] == 0, "'wcond_ok' is set after failing write-conditional");
  ASSERTM (Read (0, adr) == id+2, "memory has changed after failing write-conditional");
}


void RunTest (CMemory *mem) {
  TWord data;
  int n;

  // Clear ports...
  for (n = 0; n < CPU_CORES; n++) {
    ClearReadPort (n);
    ClearWritePort (n);
  }

  INFO("Simulation starting...");
  reset = 1;
  run_cycle (5);
  reset = 0;

  /*
  */
  // Direct write & read...
  for (n = 0; n < WPORTS; n++) wp_direct[n] = 1;
  for (n = 0; n < RPORTS; n++) rp_direct[n] = 1;
  INFO ("Direct write & read (with single bytes)...");
  RunPartwordReadWrite (0, 0x10, 0x100);
  INFO ("Direct write & read (parallel)...");
  RunParallelReadWrite (0x20, 0x200, 4, 0x300, 16);
  INFO ("Random write & read...");
  RunRandomReadWrite (16 * CACHE_SIZE, 100);
  for (n = 0; n < WPORTS; n++) wp_direct[n] = 0;
  for (n = 0; n < RPORTS; n++) rp_direct[n] = 0;

  // Cached write & read...
  INFO ("Cached write & read (port #0, with partial words)...");
  INFO ("  same cache line...");
  RunPartwordReadWrite (0, 0x30, 0x300);
  INFO ("  multiple cache lines (no conflicts)...");
  RunPartwordReadWrite (0, 0x40, 0x400, 4, 10);
  INFO ("  with conflicts (to force replacements)...");
  RunPartwordReadWrite (0, 0x50, 0x508, CACHE_SIZE, 3);   // provoke replacements

  INFO ("Cached write & read (parallel)...");
  RunParallelReadWrite (0x60, 0x600, 4, 0x680, 16);
  RunParallelReadWrite (0x70, 0x700, 16, 0x780, 4);

  INFO ("Cached random write & read (no conflict & capacity misses)...");
  RunRandomReadWrite (CACHE_SIZE, 100);

  INFO ("Cached random write & read...");
  RunRandomReadWrite (4 * CACHE_SIZE, 1000);

  // Special operations...
  INFO ("Special operations...");
  RunSpecial (0, 0xab00, 0x13);

  // LL/SC...
  INFO ("Load-Link and Store-Conditional...");
  RunLlSc (0xac00, 0x20);

  // Performance test...
  INFO ("Performance measurements...");
  RunPerformanceTest (0x10000, 0x1000);

  // Simulation finished...
  INFO ("Simulation finished.");
  //INFO ("Simulation finished. Final memory content follows.");
  //mem->Dump ();

  run_cycle (1);   // Wait some time...
}





// **************** Main ************************


int sc_main (int argc, char *argv []) {
  CMemory memory;
  int n;

  sc_set_time_resolution (1.0, SC_NS);

  MPeripherals peri ("Peripherals", &memory, NULL);
  peri.clk_i (clk);
  peri.rst_i (reset);
  peri.stb_i (wb_stb);
  peri.cyc_i (wb_cyc);
  peri.we_i (wb_we);
  peri.ack_o (wb_ack);
  peri.err_o (wb_err);
  peri.rty_o (wb_rty);
  peri.sel_i (wb_sel);
  peri.adr_i (wb_adr);
  peri.dat_i (wb_dat_w);
  peri.dat_o (wb_dat_r);

  MMemu memu ("MemU");
  memu.clk (clk);
  memu.reset (reset);
  memu.wb_stb_o (wb_stb);
  memu.wb_cyc_o (wb_cyc);
  memu.wb_we_o (wb_we);
  memu.wb_ack_i (wb_ack);
  memu.wb_sel_o (wb_sel);
  memu.wb_adr_o (wb_adr);
  memu.wb_dat_o (wb_dat_w);
  memu.wb_dat_i (wb_dat_r);
  for (n = 0; n < RPORTS; n++) {
    memu.rp_rd[n] (rp_rd [n]);
    memu.rp_direct[n] (rp_direct [n]);
    memu.rp_ack[n] (rp_ack [n]);
    memu.rp_bsel[n] (rp_bsel [n]);
    memu.rp_adr[n] (rp_adr [n]);
    memu.rp_data[n] (rp_data [n]);
  }
  for (n = 0; n < WPORTS; n++) {
    memu.wp_wr[n] (wp_wr [n]);
    memu.wp_direct[n] (wp_direct [n]);
    memu.wp_bsel[n] (wp_bsel [n]);
    memu.wp_ack[n] (wp_ack [n]);
    memu.wp_rlink_wcond[n] (wp_rlink_wcond [n]);
    memu.wp_wcond_ok[n] (wp_wcond_ok [n]);
    memu.wp_writeback[n] (wp_writeback [n]);
    memu.wp_invalidate[n] (wp_invalidate [n]);
    memu.wp_adr[n] (wp_adr [n]);
    memu.wp_data[n] (wp_data [n]);
  }

  // Init trace file...
  sc_trace_file *tf = sc_create_vcd_trace_file ("memu_tb");
  trace_file = tf;

  tf->delta_cycles (false);

  TRACE(tf, clk);
  TRACE(tf, reset);

  TRACE(tf, wb_stb);
  TRACE(tf, wb_cyc);
  TRACE(tf, wb_we);
  TRACE(tf, wb_ack);
  TRACE(tf, wb_err);
  TRACE(tf, wb_rty);
  TRACE(tf, wb_sel);
  TRACE(tf, wb_adr);
  TRACE(tf, wb_dat_w);
  TRACE(tf, wb_dat_r);

  TRACE_BUS(tf, rp_rd, RPORTS);
  TRACE_BUS(tf, rp_direct, RPORTS);
  TRACE_BUS(tf, rp_ack, RPORTS);
  TRACE_BUS(tf, rp_bsel, RPORTS);
  TRACE_BUS(tf, rp_adr, RPORTS);
  TRACE_BUS(tf, rp_data, RPORTS);

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

  //memu.Trace (tf, 2);
  //memu.Trace (NULL, 2);
  //memu.writePorts[0]->Trace (NULL);

  // Run simulation...
  sc_start (SC_ZERO_TIME);

  RunTest (&memory);

  sc_close_vcd_trace_file (tf);

  return 0;
}