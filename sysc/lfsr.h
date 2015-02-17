/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2015 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    Basic functions to simulate a linear feedback shift register (LFSR).

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


#ifndef _LFSR_
#define _LFSR_

#include "base.h"


#define MAXLFSR 32


TWord GetPrimePoly (int degree, int select);
TWord GetNextLfsrState (TWord state, int width, TWord poly);

void DisplayLfsrTaps ();      // gibt fuer alle gespeicherten Polynome die Anzahl der XORs fuer eine modulare Impl. an


#endif
