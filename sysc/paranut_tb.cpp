/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
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
  char *elfFileName;
  int arg, dumpFrom, dumpTo;
  bool dumpVHDL;

  // Parse command line...
  dumpVHDL = false;
  dumpFrom = dumpTo = 0;
  elfFileName = NULL;
  arg = 1;
  while (arg < argc && argv[arg][0] == '-') {
    switch (argv[arg][1]) {
    case 't':
      cfgVcdLevel = MAX (0, MIN (9, argv[arg][2] - '0'));
      fprintf (stderr, "(cfg) vcdLevel = %i\n", cfgVcdLevel);
      break;
    case 'i':
      cfgInsnTrace = 1;
      break;
    case 'c':
      cfgDisableCache = 1;
      break;
    case 'm':
      dumpFrom = (int) strtol (argv[++arg], NULL, 0);
      dumpTo = (int) strtol (argv[++arg], NULL, 0);
      fprintf (stderr, "(cfg) dumping memory from 0x%x to 0x%x (%s to %s)\n", dumpFrom, dumpTo, argv[arg-1], argv[arg]);
      break;
    case 'v':
      dumpVHDL = true;
      break;
    default:
      printf ("ERROR: Unknown option '%s'.\n", argv[arg]);
      arg = argc;
    }
    arg++;
  }
  if (arg < argc) elfFileName = argv[arg];
  if (!elfFileName) {
    puts ("Usage: paranut_tb [<options>] <OR32 ELF file>\n"
          "\n"
          "Options:\n"
          "  -t<n>: set VCD trace level (0 = no trace file; default = 2)\n"
          "  -i: generate instruction trace\n"
          "  -c: disable caching\n"
          "  -m <from> <to>: dump memory region before/after running the program\n"
          "  -v: dump program memory content to VHDL file"
         );
    return 3;
  }

  // Read ELF file...
  fprintf (stderr, "(sim) Reading ELF file '%s'...\n", elfFileName);
  if (!memory.ReadFile (elfFileName, dumpVHDL)) {
    printf ("ERROR: Unable to read ELF file '%s'.\n", elfFileName);
    return 3;
  }
  fprintf (stderr, "\n");

  if (dumpFrom < dumpTo) {
    printf ("(sim) Begin memory dump from 0x%x to 0x%x\n", dumpFrom, dumpTo);
    memory.Dump (dumpFrom, dumpTo);
    printf ("(sim) End memory dump\n\n");
  }

  //trace_verbose = true;

  // SystemC elaboration...
  fprintf (stderr, "(sim) Starting SystemC elaboration...\n");
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
  if (cfgVcdLevel > 0) {
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

    nut.Trace (tf, cfgVcdLevel);
  }
  else {
    fprintf (stderr, "Tracing is disabled.\n");
    tf = NULL;
  }

  //nut.Trace (NULL, 3);   // Display signal names

  // Run simulation...
  fprintf (stderr, "(sim) Starting SystemC simulation...\n\n");
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
  nut.DisplayStatistics ();

  if (dumpFrom < dumpTo) {
    printf ("\n(sim) Begin memory dump from 0x%x to 0x%x\n", dumpFrom, dumpTo);
    memory.Dump (dumpFrom, dumpTo);
    printf ("(sim) End memory dump\n\n");
  }

  return 0;
}
