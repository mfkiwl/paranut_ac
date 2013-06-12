/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2012 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This is a testbench for the ParaNut.

 *************************************************************************/


#include "peripherals.h"
#include "paranut.h"

#include <stdio.h>

#include <systemc.h>


// **************** Signals *********************


sc_signal<bool> clk, reset;
sc_signal<bool> wb_stb, wb_cyc, wb_we, wb_ack, wb_err, wb_rty;
sc_signal<sc_uint<4> > wb_sel;
sc_signal<TWord> wb_adr, wb_dat_w, wb_dat_r;





// **************** Helpers *********************


#define CLK_PERIOD 10.0


void run_cycles (int n = 1) {
  for (int k = 0; k < n; k++) {
    clk = 1;
    sc_start (CLK_PERIOD / 2, SC_NS);
    clk = 0;
    sc_start (CLK_PERIOD / 2, SC_NS);
  }
}





// **************** Main ************************


int sc_main (int argc, char *argv []) {
  CMemory memory;
  CUart uart;

  // Read ELF file...
  fprintf (stderr, "\n");
  if (argc != 2) {
    puts ("Usage: paranut_tb <OR32 ELF file>");
    return 3;
  }
  if (!memory.ReadFile (argv[1])) {
    printf ("ERROR: Unable to read ELF file '%s'.\n", argv[1]);
    return 3;
  }
  fprintf (stderr, "\n");
  // memory.Dump ();
  // memory.Dump (0x700, 0xfff);


  //trace_verbose = true;

  // SystemC elaboration...
  sc_set_time_resolution (1.0, SC_NS);

  MPeripherals peri ("peripherals", &memory, &uart);
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

  MParanut nut ("nut");
  nut.clk_i (clk);
  nut.rst_i (reset);
  nut.stb_o (wb_stb);
  nut.cyc_o (wb_cyc);
  nut.we_o (wb_we);
  nut.ack_i (wb_ack);
  nut.err_i (wb_err);
  nut.rty_i (wb_rty);
  nut.sel_o (wb_sel);
  nut.adr_o (wb_adr);
  nut.dat_o (wb_dat_w);
  nut.dat_i (wb_dat_r);

  // Trace file...
  sc_trace_file *tf;
  if (1) {
    tf = sc_create_vcd_trace_file ("paranut_tb");
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

    nut.Trace (tf, 2);
  }
  else {
    fprintf (stderr, "Tracing is disabled.\n");
    tf = NULL;
  }

  //nut.Trace (NULL, 3);   // Display signal names

  // Run simulation...
  sc_start (SC_ZERO_TIME);

  INFO ("Reset...");
  reset = 1;
  run_cycles (3);
  INFO ("Running...");
  reset = 0;
  while (!nut.IsHalted ()) run_cycles (1);
  INFO ("CePU has reached HALT instruction.");
  run_cycles (100);
  INFO ("Simulation finished.");

  if (tf) sc_close_vcd_trace_file (tf);

  // memory.Dump (0x700, 0xfff);   // for "test_all.S"

  return 0;
}