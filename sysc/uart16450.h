/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This module simulates a UART 16450 and is used for the SystemC
    testbench of the ParaNut.

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


#ifndef _UART16450_
#define _UART16450_

#include "base.h"


class CUart {
public:
  CUart () { Init (); }
  CUart (TWord _baseAdr) { Init (_baseAdr); }
  ~CUart () { Done (); }

  void Init (TWord _baseAdr = 0x90000000);
  void Done ();

  TWord GetBaseAdr () { return baseAdr; }
  bool IsAdressed (TWord adr) { return (adr & ~0xf) == baseAdr; }

  void WriteByte (TWord adr, TByte val);
  TByte ReadByte (TWord adr);
  bool IsIrqPending () { return irqPending; }

  int Simulate (int steps);   // advances timer by 'steps' time steps;
                              // returns relative time of next event

  // internal...
  void SetIrqPending (bool _val) { irqPending = _val; }

  void SchedAdd (void (*jobFunc) (void *), void *jobParam, int jobTime, const char *jobName);
  void SchedFindRemove (void (*jobFunc) (void *), void *jobParam);

protected:
  struct dev_16450 *uart;
  bool irqPending;
  TWord baseAdr;

  class CEvent *firstEvent;
  int curTime;
};


#endif
