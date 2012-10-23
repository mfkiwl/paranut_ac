/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2012 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This module simulates the system bus together with the memory and
    peripherals for the SystemC testbench of the ParaNut.

 *************************************************************************/


#ifndef _PERIPHERALS_
#define _PERIPHERALS_


#include <systemc.h>

#include "memory.h"
#include "uart16450.h"



SC_MODULE(MPeripherals) {
  SC_HAS_PROCESS(MPeripherals);

  // Ports (WISHBONE slave)...
  sc_in_clk            clk_i;     // clock input
  sc_in<bool>          rst_i;     // reset

  sc_in<bool>          stb_i;     // strobe input
  sc_in<bool>          cyc_i;     // cycle valid input
  sc_in<bool>          we_i;      // indicates write transfer
  sc_in<sc_uint<4> >   sel_i;     // byte select inputs
  sc_out<bool>         ack_o;     // normal termination
  sc_out<bool>         err_o;     // termination w/ error
  sc_out<bool>         rty_o;     // termination w/ retry

  sc_in<TWord>  adr_i;     // address bus inputs
  sc_in<TWord>  dat_i;     // input data bus
  sc_out<TWord> dat_o;     // output data bus

  // Ports (other)...
  // sc_out<bool>       int_o;     // Interrupt

  // Constructor...
  MPeripherals (sc_module_name instName, CMemory *_memory, CUart *_uart) : sc_module (instName) {
    SC_CTHREAD (MainThread, clk_i.pos ());
      reset_signal_is (rst_i, true);

    SC_CTHREAD (UartThread, clk_i.pos ());
      reset_signal_is (rst_i, true);

    memory = _memory;
    uart = _uart;
  }

  // SC methods...
  void MainThread (void);
  void UartThread (void);

  // Other methods...

  // Fields...
  CMemory *memory;
  CUart *uart;
};


#endif
