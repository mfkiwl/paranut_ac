/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2012 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

 *************************************************************************/


#include "peripherals.h"


#define WRITE_DELAY 10
#define READ_DELAY 10

// TBD: Allow real zero-delays (for testing purposes)



void MPeripherals::MainThread (void) {
  TWord adr, val, sel;
  int n;

  rty_o = 0;

  while (true) {
    ack_o = 0;
    err_o = 0;
    wait ();
    if (stb_i == 1 && cyc_i == 1) {
      if (we_i == 1) {

        // Write transfer...
        adr = adr_i.read ();
        val = dat_i.read ();
        sel = sel_i.read ();
        if (WRITE_DELAY > 0) wait (WRITE_DELAY);
	if (uart && uart->IsAdressed (adr)) {
          //INFOF (("UART: Write (%08x, %08x) [%x]", adr, val, sel));
          for (n = 0; n < 4; n++)
            if (sel & (1 << n)) uart->WriteByte (adr + n, (val >> (24-8*n)) & 0xff);
          ack_o = 1;
        }
        else if (memory->IsAdressed (adr)) {
          if (sel == 15) memory->WriteWord (adr, val);
          else for (n = 0; n < 4; n++)
            if (sel & (1 << n)) memory->WriteByte (adr + n, (val >> (24-8*n)) & 0xff);
          ack_o = 1;
        }
        else {
          //err_o = 1;
          WARNINGF (("Write access to non-existing address: %08x - ignoring", adr));
          ack_o = 1;
        }
        wait ();
      }
      else {

        // Read transfer...
        adr = adr_i.read ();
        sel = sel_i.read ();
        val = 0;
        if (READ_DELAY > 0) wait (READ_DELAY);
        if (uart && uart->IsAdressed (adr)) {
          for (n = 0; n < 4; n++)
            if (sel & (1 << n)) val |= uart->ReadByte (adr + n) << (24-8*n);
	  //INFOF (("UART: Read (%08x, %08x) [%x]", adr, val, sel));
          dat_o = val;
          ack_o = 1;
        }
        else if (memory->IsAdressed (adr)) {
          if (sel == 15) val = memory->ReadWord (adr);
          else for (n = 0; n < 4; n++)
            if (sel & (1 << n)) val |= memory->ReadByte (adr + n) << (24-8*n);
          dat_o = val;
          ack_o = 1;
        }
        else {
          //err_o = 1;
          WARNINGF (("Read access to non-existing address: %08x - returning all-one", adr));
          dat_o = 0xffffffff;
          ack_o = 1;
        }

        wait ();
      }
    }
  }
}


void MPeripherals::UartThread (void) {
  while (1) {
    wait (10);
    if (uart) uart->Simulate (100);  // factor 10 acceleration
  }
}

