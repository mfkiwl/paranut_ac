/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2012 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    Basic functions to simulate a linear feedback shift register (LFSR).

 *************************************************************************/


#ifndef _LFSR_
#define _LFSR_

#include "base.h"


#define MAXLFSR 32


TWord GetPrimePoly (int degree, int select);
TWord GetNextLfsrState (TWord state, int width, TWord poly);

void DisplayLfsrTaps ();      // gibt fuer alle gespeicherten Polynome die Anzahl der XORs fuer eine modulare Impl. an


#endif
